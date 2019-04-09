#!/usr/bin/python
# @lint-avoid-python-3-compatibility-imports
#
# clone-exec-dtpp Trace new processes via clone() and exec() syscalls.
#           For Linux, uses BCC, eBPF. Embedded C.
#
# USAGE: clone-exec-dtpp [-h] [-ne NAME_EXEC] [-nc NAME_CLONE]
#
# Copyright 2016 Netflix, Inc.
# Licensed under the Apache License, Version 2.0 (the "License")
#
# 07-Feb-2016   Brendan Gregg   Created this.
# 08-Abr-2019   Paulo Feitosa   Extended this.

from __future__ import print_function
from bcc import BPF
from bcc.utils import ArgString, printb
import bcc.utils as utils
import argparse
import re
from collections import defaultdict

# arguments
examples = """examples:
    python clone-exec-dtpp           # trace all clone() syscalls
    python clone-exec-dtpp -ne java   # only print exec syscall with command lines containing "java" as binary
    python clone-exec-dtpp -nc execute   # only print clone syscall with command lines containing "execute"
"""
parser = argparse.ArgumentParser(
    description="Trace clone() and exec() syscalls",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog=examples)
parser.add_argument("-ne", "--name-exec",
    type=ArgString,
    help="only print exec syscalls with commands matching this name (regex), any arg")
parser.add_argument("-nc", "--name-clone",
    type=ArgString,
    help="only print clone syscalls with commands matching this name (regex), any arg")
parser.add_argument("--ebpf", action="store_true",
    help=argparse.SUPPRESS)
args = parser.parse_args()

# define BPF clone program 
bpf_text = """
#include <uapi/linux/ptrace.h>
#include <linux/sched.h>
#include <linux/fs.h>

#define ARGSIZE  128

enum event_type {
    EVENT_ARG,
    EVENT_RET,
};

enum sys_type {
    CLONE,
    EXECVE,
};

struct data_t {
    u32 pid;  // PID as in the userspace term (i.e. task->tgid in kernel)
    u32 ppid; // Parent PID as in the userspace term (i.e task->real_parent->tgid in kernel)
    char comm[TASK_COMM_LEN];
    char argv[ARGSIZE];
    enum event_type type;
    enum sys_type stype;
    u64 ts;
    int retval;
};

BPF_PERF_OUTPUT(events);

int syscall__clone(struct pt_regs *ctx)
{
    u64 event_ts = bpf_ktime_get_ns();
    // create data here and pass to submit_arg to save stack space (#555)
    struct data_t data = {};
    struct task_struct *task;

    data.ts = event_ts;
    data.pid = bpf_get_current_pid_tgid() >> 32;

    task = (struct task_struct *)bpf_get_current_task();
    data.ppid = task->real_parent->tgid;

    bpf_get_current_comm(&data.comm, sizeof(data.comm));
    data.type = EVENT_ARG;
    data.stype = CLONE;

    events.perf_submit(ctx, &data, sizeof(data));

    return 0;
}

int do_ret_sys_clone(struct pt_regs *ctx)
{
    u64 event_ts = bpf_ktime_get_ns();
    struct data_t data = {};
    struct task_struct *task;

    data.ts = event_ts;
    data.pid = bpf_get_current_pid_tgid() >> 32;

    task = (struct task_struct *)bpf_get_current_task();
    data.ppid = task->real_parent->tgid;

    bpf_get_current_comm(&data.comm, sizeof(data.comm));
    data.type = EVENT_RET;
    data.stype = CLONE;
    data.retval = PT_REGS_RC(ctx);
    events.perf_submit(ctx, &data, sizeof(data));

    return 0;
}

static int __submit_arg(struct pt_regs *ctx, void *ptr, struct data_t *data)
{
    bpf_probe_read(data->argv, sizeof(data->argv), ptr);
    events.perf_submit(ctx, data, sizeof(struct data_t));
    return 1;
}

int syscall__execve(struct pt_regs *ctx,
    const char __user *filename,
    const char __user *const __user *__argv,
    const char __user *const __user *__envp)
{
    u64 event_ts = bpf_ktime_get_ns();
    // create data here and pass to submit_arg to save stack space (#555)
    struct data_t data = {};
    struct task_struct *task;

    data.ts = event_ts;
    data.pid = bpf_get_current_pid_tgid() >> 32;

    task = (struct task_struct *)bpf_get_current_task();
    data.ppid = task->real_parent->tgid;

    bpf_get_current_comm(&data.comm, sizeof(data.comm));
    data.type = EVENT_ARG;
    data.stype = EXECVE;

    __submit_arg(ctx, (void *)filename, &data);

    return 0;
}

int do_ret_sys_execve(struct pt_regs *ctx)
{
    u64 event_ts = bpf_ktime_get_ns();
    struct data_t data = {};
    struct task_struct *task;

    data.ts = event_ts;
    data.pid = bpf_get_current_pid_tgid() >> 32;

    task = (struct task_struct *)bpf_get_current_task();
    data.ppid = task->real_parent->tgid;

    bpf_get_current_comm(&data.comm, sizeof(data.comm));
    data.type = EVENT_RET;
    data.stype = EXECVE;
    data.retval = PT_REGS_RC(ctx);
    events.perf_submit(ctx, &data, sizeof(data));

    return 0;
}
"""

if args.ebpf:
    print(bpf_text)
    exit()

# initialize BPF probes
b = BPF(text=bpf_text)
clone_fnname = b.get_syscall_fnname("clone")
execve_fnname = b.get_syscall_fnname("execve")
b.attach_kprobe(event=clone_fnname, fn_name="syscall__clone")
b.attach_kretprobe(event=clone_fnname, fn_name="do_ret_sys_clone")
b.attach_kprobe(event=execve_fnname, fn_name="syscall__execve")
b.attach_kretprobe(event=execve_fnname, fn_name="do_ret_sys_execve")

# headers
print("Header: [%s, %s, %s, %s, %s, %s]" % ("PID", "P_PID", "RET_VAL", "START_TS", "END_TS", "P_COMM"))

class EventType(object):
    EVENT_ARG = 0
    EVENT_RET = 1

class SysType(object):
    CLONE = 0
    EXECVE = 1

argv_clone = defaultdict(list)
argv_exec = defaultdict(list)

# This is best-effort PPID matching. Short-lived processes may exit
# before we get a chance to read the PPID.
# This is a fallback for when fetching the PPID from task->real_parent->tgip
# returns 0, which happens in some kernel versions.
def get_ppid(pid):
    try:
        with open("/proc/%d/status" % pid) as status:
            for line in status:
                if line.startswith("PPid:"):
                    return int(line.split()[1])
    except IOError:
        pass
    return 0

# process events
def print_event(event, event_name, argv_map):
    if event.type == EventType.EVENT_ARG:
        argv_map[event.pid].append(event)
    elif event.type == EventType.EVENT_RET:
        try:
            arg_event = argv_map[event.pid].pop(0)
            ppid = event.ppid if event.ppid > 0 else get_ppid(event.pid)
            ppid = b"%d" % ppid if ppid > 0 else b"?"
            printb(b"[%d, %s, %d, %d, %d] %s: %s" % 
                (event.pid, ppid, event.retval, arg_event.ts, event.ts, event_name, event.comm))
        except Exception as e:
            printb(b"[%d, %d, %d] %s invalid state, possible data race (there is no arg event): %s" % 
                (event.pid, event.retval, event.ts, event_name, event.comm))
            pass
    else:
        printb("Cannot identify event type %s of event %s" % (event.type, event_name))
        raise Exception()

def get_sys_name(stype):
    if stype == SysType.CLONE:
        return "clone"
    elif stype == SysType.EXECVE:
        return "execve"
    else:
        return "unknown"

def print_perf_event(cpu, data, size):
    event = b["events"].event(data)
    sys_name = get_sys_name(event.stype)
    skip = False

    if sys_name == "clone":
        if args.name_clone and not re.search(bytes(args.name_clone), event.comm):
            skip = True
        argv_map = argv_clone
    elif sys_name == "execve":
        if args.name_exec:
            if event.type == EventType.EVENT_ARG and not re.search(bytes(args.name_exec), event.argv):
                skip = True
            elif event.type == EventType.EVENT_RET and not re.search(bytes(args.name_exec), event.comm):
                skip = True
        argv_map = argv_exec
    else:
        printb("unknown syscall event")
        skip = True

    if not skip:
        print_event(event, sys_name, argv_map)

# loop with callback to print events
b["events"].open_perf_buffer(print_perf_event)
while 1:
    try:
        b.perf_buffer_poll()
    except KeyboardInterrupt:
        try:
            del(argv_clone)
            del(argv_exec)
        except Exception:
            pass
        exit()
