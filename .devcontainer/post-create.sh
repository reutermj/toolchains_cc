#!/bin/bash
set -euox pipefail

# Install Claude Code
curl -fsSL https://claude.ai/install.sh | bash

# Install beads MCP (git-backed issue tracker for AI agents)
curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash
