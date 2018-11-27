#/bin/bash

docker build --no-cache -t pfelipefeitosa/heavy-handler:test -f Dockerfile-test-version .
#docker push pfelipefeitosa/heavy-handler:test
