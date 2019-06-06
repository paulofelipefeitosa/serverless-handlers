# Noop HTTP Server

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
