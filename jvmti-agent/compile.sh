#!/bin/bash
set -e

JVM_LIBRARY=$1

echo "Compiling agent.c"
gcc -Wl, -g -fno-strict-aliasing -fPIC -fno-omit-frame-pointer -W -Wall  -Wno-unused -Wno-parentheses -I "$JVM_LIBRARY/include/" -I "$JVM_LIBRARY/include/linux" -c -o agent.o agent.c

echo "Generating libagent.so"
gcc -shared -o libagent.so agent.o

echo "Compiling Java Code for Test"
javac Nothing.java

