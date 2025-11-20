#!/bin/bash
set -euox pipefail

mkdir -p ~/.vscode
cp .devcontainer/settings.json .vscode/

# Install Claude Code
curl -fsSL https://claude.ai/install.sh | bash

# Install beads MCP (git-backed issue tracker for AI agents)
curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash

# Initialize beads in the project if it's not already initialized
if [ ! -d ".beads" ]; then
  bd init --quiet
fi
