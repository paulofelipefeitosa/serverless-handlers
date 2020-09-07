# Noop Class Loader HTTP Server

## Build
You can build the whole project running just a maven command as below:

```bash
mvn clean install
```

## Download Synthetic Functions Jars
Due to the fact that GitHub does not allow files larger than 100MB, the synthetic functions jars are available [here](https://drive.google.com/drive/folders/1may8W9W25W8LnQ5dxIX0aCtMlLPjewcq?usp=sharing).

## Rebuild NoOp App Jar
The NoOp Class Loader will fetch&load the synthetic classes on its own jar, so it is necessary to merge the synthetic function jar with the NoOp Class Loader jar.

## Run
After running maven and build the project you can run the server running the jar file. Some environment variables definition are required.  See an example as follow.

```bash
scale=0.1 image_url=https://i.imgur.com/BhlDUOR.jpg java -jar <path-to-the-rebuilded-jar> <path-to-synthetic-func-jar>
```

# NoOp Criu Class Loader HTTP Server 

## Compilando
```sh
mvn clean install
```

## Download Synthetic Functions Jars
Due to the fact that GitHub does not allow files larger than 100MB, the synthetic functions jars are available [here](https://drive.google.com/drive/folders/1may8W9W25W8LnQ5dxIX0aCtMlLPjewcq?usp=sharing).

## Rebuild NoOp
The NoOp CRIU Class Loader will fetch and load the synthetic classes on its own directory, so it is necessary to write the synthetic functions classes on the NoOp Criu Project Directory.

## Run
```sh
# Vai subir um servidor HTTP na porta 9000
setsid java -jar <path-to-the-rebuilded-jar> <path-to-synthetic-func-jar> < /dev/null &> app.log &
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
