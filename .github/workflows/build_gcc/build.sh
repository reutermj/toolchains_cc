#!/bin/bash
set -euox pipefail

# Usage: Run from repo root with GCC version and GitHub token
#   .github/workflows/build_gcc/build.sh <GCC_VERSION> <GH_TOKEN>

docker build \
    -f .github/workflows/build_gcc/Dockerfile \
    --build-arg GCC_VERSION="${1}" \
    --build-arg GH_TOKEN="${2}" \
    -t gcc \
    .

CONTAINER_ID=$(docker create gcc)
docker cp "${CONTAINER_ID}:/tmp/artifacts/." .
docker rm "${CONTAINER_ID}"

