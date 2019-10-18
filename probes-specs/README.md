# Experiments Probes

## I/O Operations

### Install
[BCC Tool Install](https://github.com/iovisor/bcc/blob/master/INSTALL.md).

### Run
```sh
python -u biosnoop.py > $BCC_TOOL_OUT &
```

### Parse
Running the I/O stats parser.
```sh
```

## Clone and Execve Traces

### Install
[BPFTrace Install](https://github.com/iovisor/bpftrace/blob/master/INSTALL.md).

### Run
Running the execve, clone & fork probes. Possible args: "execute-request" ["/usr/bin/java", "/usr/bin/node", "/usr/sbin/criu", "/usr/bin/python3"].
```sh
bpftrace -B 'line' execve-clone-probes.bt <program_command> <executor_binary> > $BPFTRACE_OUT &
```

### Parse
Running the execve, clone & fork probes parser.
```sh
python -u execve-clone-parser-bpftrace.py <executionID> < $BPFTRACE_OUT
```

## JVMTI Agent

### Compile
Compiling JVMTI Agent.
``` sh
gcc -Wl, -g -fno-strict-aliasing -fPIC -fno-omit-frame-pointer -W -Wall  -Wno-unused -Wno-parentheses -I "$JVM_LIBRARY/include/" -I "$JVM_LIBRARY/include/linux" -c -o agent.o agent.c
gcc -shared -o libagent.so agent.o
```

### Run
Running Java App with JVMTI Agent.
``` sh
LD_LIBRARY_PATH=`pwd` java -agentlib:sample_agent=<output-filepath> Nothing
```

## CRIU

### Parse

Running CRIU restore statistics parser.
```sh
python -u criu-restore-parser.py <executionID> < <path-to-criu-restore-log>
```