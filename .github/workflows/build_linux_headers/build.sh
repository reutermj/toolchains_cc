#!/bin/bash
set -euox pipefail

# Usage: Run from repo root with Linux version, target, and GitHub token
#   .github/workflows/build_linux_headers/build.sh <LINUX_VERSION> <TARGET> <GH_TOKEN>
#   .github/workflows/build_linux_headers/build.sh 6.18 aarch64-linux <GH_TOKEN>

docker build \
    -f .github/workflows/build_linux_headers/Dockerfile \
    --build-arg LINUX_VERSION="${1}" \
    --build-arg TARGET="${2}" \
    --build-arg GH_TOKEN="${3}" \
    -t linux-headers \
    .

CONTAINER_ID=$(docker create linux-headers)
docker cp "${CONTAINER_ID}:/tmp/artifacts/." .
docker rm "${CONTAINER_ID}"
