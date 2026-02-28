#!/bin/bash
set -euox pipefail

# Usage: Run from repo root with glibc version, target, and GitHub token
#   .github/workflows/build_glibc/build.sh <GLIBC_VERSION> <LINUX_VERSION> <TARGET> <GH_TOKEN>
#   .github/workflows/build_glibc/build.sh 2.28 6.18 aarch64-linux-gnu <GH_TOKEN>

docker build \
    -f .github/workflows/build_glibc/Dockerfile \
    --build-arg GLIBC_VERSION="${1}" \
    --build-arg LINUX_VERSION="${2}" \
    --build-arg TARGET="${3}" \
    --build-arg GH_TOKEN="${4}" \
    -t glibc \
    .

CONTAINER_ID=$(docker create glibc)
docker cp "${CONTAINER_ID}:/tmp/artifacts/." .
docker rm "${CONTAINER_ID}"
