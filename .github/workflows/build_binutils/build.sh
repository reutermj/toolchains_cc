#!/bin/bash
set -euox pipefail

# Usage: Run from repo root with binutils version and GitHub token
#   .github/workflows/build_binutils/build.sh <BINUTILS_VERSION> <GH_TOKEN>

BINUTILS_VERSION="${1}"
GH_TOKEN="${2}"

docker build \
    -f .github/workflows/build_binutils/Dockerfile \
    --build-arg BINUTILS_VERSION="${BINUTILS_VERSION}" \
    --build-arg GH_TOKEN="${GH_TOKEN}" \
    -t binutils \
    .

CONTAINER_ID=$(docker create binutils)
docker cp "${CONTAINER_ID}:/tmp/artifacts/." .
docker rm "${CONTAINER_ID}"
