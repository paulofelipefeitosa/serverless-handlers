# Noop HTTP Server

## Build
You can build the whole project running just a maven command as below:

```bash
mvn clean install
```

## Run
After running maven and build the project you can run the server running the jar file. Some environment variables definition are required.  See an example as follow.

```bash
java -jar target/noop-server-maven-0.0.1-SNAPSHOT.jar
```

# Noop CRIU HTTP Server

## Compilando
```sh
mvn clean install
```

## Executando
```sh
# Vai subir um servidor HTTP na porta 9000
setsid java -jar target/app-0.0.1-SNAPSHOT.jar < /dev/null &> app.log &
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

## Outros Comandos


```sh
# PID dos processos
ps -C java 

# Trucar arquivos
truncate --size=0 app.log

# pegar a porta que o processo está rodando
netstat -tulpn | grep $(pgrep java)
```
