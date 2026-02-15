#!/bin/bash
set -euox pipefail

# Usage: Run from repo root with binutils version, target, and GitHub token
#   .github/workflows/build_binutils/build.sh <BINUTILS_VERSION> <TARGET> <GH_TOKEN>
#   .github/workflows/build_binutils/build.sh <BINUTILS_VERSION> <TARGET> 
#
# Examples:
#   .github/workflows/build_binutils/build.sh 2.45 x86_64-linux-gnu <token>
#   .github/workflows/build_binutils/build.sh 2.45 x86_64-linux-musl <token>

docker build \
    -f .github/workflows/build_binutils/Dockerfile \
    --build-arg BINUTILS_VERSION="${1}" \
    --build-arg TARGET="${2}" \
    --build-arg GH_TOKEN="${3}" \
    -t binutils \
    .

CONTAINER_ID=$(docker create binutils)
docker cp "${CONTAINER_ID}:/tmp/artifacts/." .
docker rm "${CONTAINER_ID}"
