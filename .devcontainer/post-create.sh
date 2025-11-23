#!/bin/bash
set -euox pipefail

# Install Claude Code
curl -fsSL https://claude.ai/install.sh | bash

# Install beads
curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash

# Install beads-mcp
pip3 install beads-mcp

# Start beads daemon with auto-commit and auto-push
bd daemon start --auto-commit --auto-push
