#!/bin/bash
echo "Running HTTP Server"
scale=0.1 image_url=https://i.imgur.com/BhlDUOR.jpg java -jar target/thumbnailator-server-maven-0.0.1-SNAPSHOT.jar > log.out 2> log.err &
sleep 10

echo "Executing Requests"
python execute-requests.py