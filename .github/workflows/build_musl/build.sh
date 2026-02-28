#!/bin/bash
set -euox pipefail

# Usage: Run from repo root with musl version, target, and GitHub token
#   .github/workflows/build_musl/build.sh <MUSL_VERSION> <TARGET> <GH_TOKEN>
#   .github/workflows/build_musl/build.sh 1.2.5 aarch64-linux-musl <GH_TOKEN>

docker build \
    -f .github/workflows/build_musl/Dockerfile \
    --build-arg MUSL_VERSION="${1}" \
    --build-arg TARGET="${2}" \
    --build-arg GH_TOKEN="${3}" \
    -t musl \
    .

CONTAINER_ID=$(docker create musl)
docker cp "${CONTAINER_ID}:/tmp/artifacts/." .
docker rm "${CONTAINER_ID}"
