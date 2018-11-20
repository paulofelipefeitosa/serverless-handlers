#/bin/bash

docker build --no-cache -t pfelipefeitosa/builtinhandler:test -f Dockerfile-test-version .
docker push pfelipefeitosa/builtinhandler:test
