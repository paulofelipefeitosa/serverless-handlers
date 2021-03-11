#!/bin/bash
set +e

echo "Removing any previous SEUSS native container"
docker ps --filter name=ebbrt* --filter status=running -aq | xargs docker stop
docker ps --filter name=ebbrt* -aq | xargs docker rm

echo "Removing any previous SEUSS hosted container"
docker ps --filter name=mycontainer --filter status=running -aq | xargs docker stop
docker ps --filter name=mycontainer -aq | xargs docker rm