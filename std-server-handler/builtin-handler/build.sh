#/bin/bash

docker build --no-cache -t pfelipefeitosa/builtinhandler:release -f Dockerfile .
docker push pfelipefeitosa/builtinhandler:release
