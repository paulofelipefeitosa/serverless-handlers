#!/usr/bin/python
# @lint-avoid-python-3-compatibility-imports
#
# biosnoop  Trace block device I/O and print details including issuing PID.
#           For Linux, uses BCC, eBPF.
#
# This uses in-kernel eBPF maps to cache process details (PID and comm) by I/O
# request, as well as a starting timestamp for calculating I/O latency.
#
# Copyright (c) 2015 Brendan Gregg.
# Licensed under the Apache License, Version 2.0 (the "License")
#
# 16-Sep-2015   Brendan Gregg   Created this.
# 11-Feb-2016   Allan McAleavy  updated for BPF_PERF_OUTPUT
# 17-Oct-2019   Paulo Feitosa   Updated to Remove Latency Measures

from __future__ import print_function
from bcc import BPF
import re
import argparse

# arguments
examples = """examples:
    ./biosnoop           # trace all block I/O
"""
parser = argparse.ArgumentParser(
    description="Trace block I/O",
    formatter_class=argparse.RawDescriptionHelpFormatter,
    epilog=examples)
parser.add_argument("--ebpf", action="store_true",
    help=argparse.SUPPRESS)
args = parser.parse_args()
debug = 0

# define BPF program
bpf_text="""
#include <uapi/linux/ptrace.h>
#include <linux/blkdev.h>
struct data_t {
    u32 pid;
    u64 rwflag;
    u64 len;
    char disk_name[DISK_NAME_LEN];
    char name[TASK_COMM_LEN];
};
BPF_PERF_OUTPUT(events);
// output
int trace_req_completion(struct pt_regs *ctx, struct request *req)
{
    struct data_t data = {};
    if (bpf_get_current_comm(&data.name, sizeof(data.name)) == 0) {
        data.pid = bpf_get_current_pid_tgid() >> 32;
        data.len = req->__data_len;
        struct gendisk *rq_disk = req->rq_disk;
        bpf_probe_read(&data.disk_name, sizeof(data.disk_name),
                       rq_disk->disk_name);
    }
/*
 * The following deals with a kernel version change (in mainline 4.7, although
 * it may be backported to earlier kernels) with how block request write flags
 * are tested. We handle both pre- and post-change versions here. Please avoid
 * kernel version tests like this as much as possible: they inflate the code,
 * test, and maintenance burden.
 */
#ifdef REQ_WRITE
    data.rwflag = !!(req->cmd_flags & REQ_WRITE);
#elif defined(REQ_OP_SHIFT)
    data.rwflag = !!((req->cmd_flags >> REQ_OP_SHIFT) == REQ_OP_WRITE);
#else
    data.rwflag = !!((req->cmd_flags & REQ_OP_MASK) == REQ_OP_WRITE);
#endif
    events.perf_submit(ctx, &data, sizeof(data));
    return 0;
}
"""

if debug or args.ebpf:
    print(bpf_text)
    if args.ebpf:
        exit()

# initialize BPF
b = BPF(text=bpf_text)
b.attach_kprobe(event="blk_account_io_completion",
    fn_name="trace_req_completion")

# header
print("%-14s %-6s %-7s %-1s %-7s\n" % ("COMM", "PID",
    "DISK", "T", "BYTES"), end="")

rwflg = ""

# process event
def print_event(cpu, data, size):
    event = b["events"].event(data)

    if event.rwflag == 1:
        rwflg = "W"
    else:
        rwflg = "R"

    print("%-14.14s %-6s %-7s %-1s %-7s\n" % (event.name.decode('utf-8', 'replace'), event.pid,
        event.disk_name.decode('utf-8', 'replace'), rwflg, event.len), end="")

# loop with callback to print_event
b["events"].open_perf_buffer(print_event, page_cnt=64)
while 1:
    try:
        b.perf_buffer_poll()
    except KeyboardInterrupt:
        exit()