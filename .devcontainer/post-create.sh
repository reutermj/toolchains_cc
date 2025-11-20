#!/bin/bash
set -euox pipefail

mkdir -p ~/.vscode
cp .devcontainer/settings.json .vscode/
