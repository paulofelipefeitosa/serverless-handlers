# Markdown-Render

Renders markdown texts to HTML.

## Build
You can build the whole project running just a maven command as below:

```bash
mvn clean install
```

## Run
After building the project you can run the server by executing the jar file. Some environment variables definition are required. 
See the following example:
```bash
java -jar target/app-0.0.1-SNAPSHOT.jar
```

# Markdown-Render CRIU HTTP Server

## Build
```sh
mvn clean install
```

## Execute
```sh
# This command run the HTTP Server listening the port 9000
setsid java -jar target/app-0.0.1-SNAPSHOT.jar < /dev/null &> app.log &
```

## Apply Requests
```sh
curl http://localhost:9000/ping
curl http://localhost:9000/gc
```

## Using the Function
The markdown file content should be sent as a POST HTTP body.
```shell script
curl http://localhost:9000/ -X POST -H "Content-Type: text/plan" -d '<markdown-content>'
```

## Checkpoint the process state
```sh
# This command assumes there is only one Java process running in the PID namespace.
sudo criu dump -t $(ps aux | grep "java -jar" | awk 'NR==1{print $2}') -vvv -o dump.log && echo OK
```

## Restore the process
```sh
sudo criu restore -d -vvv -o restore.log && echo OK
```

## Other Commands


```sh
# Process PID
ps -C java 

# Truncate file
truncate --size=0 app.log

# Discover the port that the Java process is listening to.
netstat -tulpn | grep $(pgrep java)
```
