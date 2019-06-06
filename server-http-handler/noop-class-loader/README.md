# Noop HTTP Server

## Build
You can build the whole project running just a maven command as below:

```bash
mvn clean install
```

## Download Synthetic Functions Jars
Due to the fact that GitHub does not allow files larger than 100MB, we make jars available on this [link](https://drive.google.com/drive/folders/1may8W9W25W8LnQ5dxIX0aCtMlLPjewcq?usp=sharing).

## Run
After running maven and build the project you can run the server running the jar file. Some environment variables definition are required.  See an example as follow.

```bash
scale=0.1 image_url=https://i.imgur.com/BhlDUOR.jpg java -jar target/noop-server-maven-0.0.1-SNAPSHOT.jar <path-to-synthetic-func-jar>
```
