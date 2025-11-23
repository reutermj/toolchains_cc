#!/bin/bash
set -euox pipefail

# This bash file runs in the toolchains_cc repo root.

# This project uses Beads to provide agents with structured task tracking.
# See: https://github.com/steveyegge/beads/blob/main/README.md
curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash
pip3 install beads-mcp
bd init --quiet
bd daemon start

curl -fsSL https://claude.ai/install.sh | bash
