# Como usar

## Compilando
```sh
javac *.java
gcc -shared -fpic -I"/usr/lib/jvm/java-6-sun/include" -I"/usr/lib/jvm/java-8-oracle/include/" -I"/usr/lib/jvm/java-8-oracle/include/linux/" GC.c -o libgc.so
```

## Executando
```sh
# Vai subir um servidor HTTP na porta 9000
setsid java -Djvmtilib=${PWD}/libgc.so -classpath . App  < /dev/null &> app.log &
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

## Outros Comandos


```sh
# PID dos processos
ps -C java 

# Trucar arquivos
truncate --size=0 app.log

# pegar a porta que o processo está rodando
netstat -tulpn | grep $(pgrep java)
```