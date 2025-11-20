#!/bin/bash
set -euox pipefail

mkdir -p ~/.vscode
cp .devcontainer/settings.json .vscode/

# Install Claude Code
curl -fsSL https://claude.ai/install.sh | bash
