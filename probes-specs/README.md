# Experiments Probes

## BCC

### Install
[BCC Tool Install](https://github.com/iovisor/bcc/blob/master/INSTALL.md).

### Run
```sh
python clone-exec-dtpp.py -ne "<execve-pattern>" -nc "<clone-pattern>" > $BCC_TOOL_OUT &
```

### Parse
Running the execve, clone & fork probes parser.
```sh
python execve-clone-fork-probes-parser.py "<executionID>" < $BCC_TOOL_OUT
```

## BPFTrace

### Install
[BPFTrace Install](https://github.com/iovisor/bpftrace/blob/master/INSTALL.md).

### Run
Running the execve, clone & fork probes.
```sh
bpftrace -B 'line' execve-clone-fork-probes.bt > $BPFTRACE_OUT &
```

### Parse
Running the execve, clone & fork probes parser.
```sh
python execve-clone-fork-probes-parser.py "<executionID>" < $BPFTRACE_OUT
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
