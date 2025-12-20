#!/bin/bash
set -euox pipefail

# Usage: Run from repo root with GitHub token
#   .github/workflows/build_musl/build.sh <MUSL_VERSION> <GH_TOKEN>

docker build \
    -f .github/workflows/build_musl/Dockerfile \
    --build-arg MUSL_VERSION=$1 \
    --build-arg GH_TOKEN=$2 \
    -t musl \
    .

CONTAINER_ID=$(docker create musl)
docker cp "${CONTAINER_ID}:/tmp/artifacts/." .
docker rm "${CONTAINER_ID}"
