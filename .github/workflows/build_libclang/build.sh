#!/bin/bash
set -euox pipefail

# Usage: Run from repo root with LLVM version, zlib version, and GitHub token
#   .github/workflows/build_libclang/build.sh <LLVM_VERSION> <ZLIB_VERSION> <GH_TOKEN>
#
# Examples:
#   .github/workflows/build_libclang/build.sh 21.1.1 1.3.1 <token>

docker build \
    -f .github/workflows/build_libclang/Dockerfile \
    --build-arg LLVM_VERSION="${1}" \
    --build-arg ZLIB_VERSION="${2}" \
    --build-arg GH_TOKEN="${3}" \
    -t libclang \
    .

CONTAINER_ID=$(docker create libclang)
docker cp "${CONTAINER_ID}:/tmp/artifacts/." .
docker rm "${CONTAINER_ID}"
