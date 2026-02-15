#!/bin/bash
set -euox pipefail

# Usage: Run from repo root with GCC version and GitHub token
#   .github/workflows/build_gcc/build.sh <GCC_VERSION> <TARGET> <BOOTSTRAP> <GH_TOKEN>
#   .github/workflows/build_gcc/build.sh 15.2.0 x86_64-linux-gnu false <GH_TOKEN>
#   .github/workflows/build_gcc/build.sh 15.2.0 x86_64-bootstrap-linux-gnu true <GH_TOKEN>

docker build \
    -f .github/workflows/build_gcc/Dockerfile \
    --build-arg GCC_VERSION="${1}" \
    --build-arg TARGET="${2}" \
    --build-arg BOOTSTRAP="${3}" \
    --build-arg GH_TOKEN="${4}" \
    -t gcc \
    .

CONTAINER_ID=$(docker create gcc)
docker cp "${CONTAINER_ID}:/tmp/artifacts/." .
docker rm "${CONTAINER_ID}"

