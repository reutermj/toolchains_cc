#!/bin/bash
set -euox pipefail

# Usage: Run from repo root with GitHub token
#   .github/workflows/build_linux_headers/build.sh <LINUX_VERSION> <GH_TOKEN>
#   .github/workflows/build_linux_headers/build.sh 6.18 <GH_TOKEN>

docker build \
    -f .github/workflows/build_linux_headers/Dockerfile \
    --build-arg LINUX_VERSION=$1 \
    --build-arg GH_TOKEN=$2 \
    -t linux-headers \
    .

CONTAINER_ID=$(docker create linux-headers)
docker cp "${CONTAINER_ID}:/tmp/artifacts/." .
docker rm "${CONTAINER_ID}"
