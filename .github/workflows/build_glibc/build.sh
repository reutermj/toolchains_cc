#!/bin/bash
set -euox pipefail

# Usage: Run from repo root with GitHub token
#   .github/workflows/build_glibc/build.sh <GLIBC_VERSION> <LINUX_VERSION> <GH_TOKEN>

docker build \
    -f .github/workflows/build_glibc/Dockerfile \
    --build-arg GLIBC_VERSION=$1 \
    --build-arg LINUX_VERSION=$2 \
    --build-arg GH_TOKEN=$3 \
    -t glibc \
    .

CONTAINER_ID=$(docker create glibc)
docker cp "${CONTAINER_ID}:/tmp/artifacts/." ./artifacts/
docker rm "${CONTAINER_ID}"
