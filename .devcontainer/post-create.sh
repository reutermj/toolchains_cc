#!/bin/bash
set -euox pipefail

pwd

pushd /workspaces/toolchains_cc
pwd

curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash
pip3 install beads-mcp
bd init --quiet
bd daemon start

# Install Claude Code
curl -fsSL https://claude.ai/install.sh | bash

popd
