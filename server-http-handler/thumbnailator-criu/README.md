# Thumbnailator HTTP Server for CRIU

## Build
You can build the whole project running using the following commands:

Compiling GC.c to generate libgc.so and Java Project.

```bash
javac *.java
gcc -shared -fpic -I"/usr/lib/jvm/java-6-sun/include" -I"/usr/lib/jvm/java-8-oracle/include/" -I"/usr/lib/jvm/java-8-oracle/include/linux/" GC.c -o libgc.so
```

## Run
After running maven and build the project you can run the server running the jar file. Some environment variables definition are required.  See an example as follow.

```bash
scale=0.1 image_path=BhlDUO.jpg setsid java -Djvmtilib=${PWD}/libgc.so -classpath . App  < /dev/null &> app.log &
```

## Apply Requests

```sh
curl http://localhost:9000/ping
curl http://localhost:9000/gc
```

## Dump

```sh
# Aqui assume que apenas 1 processo java está rodando na máquina
sudo criu dump -t $(ps aux | grep "java -Djvmtilib" | awk 'NR==1{print $2}') -vvv -o dump.log && echo OK
```

## Restore

```sh
sudo criu restore -d -vvv -o restore.log && echo OK
```
