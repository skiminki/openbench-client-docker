#!/bin/bash

set -e

OPENBENCH_GIT_HASH="$(git ls-remote https://github.com/AndyGrant/OpenBench.git HEAD | head -n 1 | awk '{ print $1 }')"

docker build . \
       -t skiminki/openbench-client:latest \
       --build-arg "OPENBENCH_GIT_HASH=${OPENBENCH_GIT_HASH}"
