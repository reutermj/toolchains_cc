#!/bin/bash
set -euox pipefail

# Usage: Run from repo root with component and version
#   .github/workflows/create_source_tarballs/build.sh <COMPONENT> <VERSION>
#
# Examples:
#   .github/workflows/create_source_tarballs/build.sh musl 1.2.5
#   .github/workflows/create_source_tarballs/build.sh gcc 15.2.0

docker build \
    -f .github/workflows/create_source_tarballs/Dockerfile \
    --build-arg COMPONENT="${1}" \
    --build-arg VERSION="${2}" \
    -t create-source-tarballs \
    .

CONTAINER_ID=$(docker create create-source-tarballs)
docker cp "${CONTAINER_ID}:/tmp/artifacts/." .
docker rm "${CONTAINER_ID}"
