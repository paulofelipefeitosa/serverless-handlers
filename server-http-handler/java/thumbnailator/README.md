# Thumbnailator HTTP Server

## Build
You can build the whole project running just a maven command as below:

```bash
mvn clean install
```

## Run
After running maven and build the project you can run the server running the jar file. Some environment variables definition are required.  See an example as follow.

```bash
scale=0.1 image_url=https://i.imgur.com/BhlDUOR.jpg java -jar target/thumbnailator-server-maven-0.0.1-SNAPSHOT.jar
```

# Thumbnailator HTTP Server for CRIU

## Build
You can build the whole project running using the following commands:

Compiling GC.c to generate libgc.so and Java Project.

```bash
mvn clean install
```

## Run
After running maven and build the project you can run the server running the jar file. Some environment variables definition are required.  See an example as follow.

```bash
scale=0.1 image_path=BhlDUOR.jpg setsid java -jar target/app-0.0.1-SNAPSHOT.jar < /dev/null &> app.log &
```

## Apply Requests

```sh
curl http://localhost:9000/ping
curl http://localhost:9000/gc
```

## Dump

```sh
# Aqui assume que apenas 1 processo java está rodando na máquina
sudo criu dump -t $(ps aux | grep "java -jar" | awk 'NR==1{print $2}') -vvv -o dump.log && echo OK
```

## Restore

```sh
sudo criu restore -d -vvv -o restore.log && echo OK
```
