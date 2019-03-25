Compiling JVMTI Agent.
``` sh
gcc -Wl, -g -fno-strict-aliasing -fPIC -fno-omit-frame-pointer -W -Wall  -Wno-unused -Wno-parentheses -I "$JVM_LIBRARY/include/" -I "$JVM_LIBRARY/include/linux" -c -o agent.o agent.c
gcc -shared -o libagent.so agent.o
```

Running Java App with JVMTI Agent
``` sh
LD_LIBRARY_PATH=`pwd` java -agentlib:sample_agent=<output-filepath> Nothing
```