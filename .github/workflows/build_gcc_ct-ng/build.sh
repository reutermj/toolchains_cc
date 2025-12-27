#!/bin/bash
set -euox pipefail

docker build \
    --build-arg GCC_VERSION=$1 \
    --build-arg LIBC=$2 \
    --build-arg LIBC_VERSION=$3 \
    -t ct-ng \
    .

# CONTAINER_ID=$(docker create ct-ng)
# docker cp "${CONTAINER_ID}:/tmp/work/build.log" .
# docker rm "${CONTAINER_ID}"
