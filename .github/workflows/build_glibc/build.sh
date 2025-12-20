#!/bin/bash
set -euox pipefail

# Usage: Run from repo root with GitHub token
#   .github/workflows/build_glibc/build.sh <GH_TOKEN>

docker build \
    -f .github/workflows/build_glibc/Dockerfile \
    --build-arg GH_TOKEN=$1 \
    -t glibc \
    .

CONTAINER_ID=$(docker create glibc)
docker cp "${CONTAINER_ID}:/tmp/artifacts/." ./artifacts/
docker rm "${CONTAINER_ID}"
