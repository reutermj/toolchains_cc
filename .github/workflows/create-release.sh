#!/bin/bash
set -euox pipefail

DATE=$(grep -o 'version = "[^"]*"' MODULE.bazel | cut -d '"' -f 2 | head -n 1)
SRC_TAR="toolchains_cc-$DATE.tar.gz"
gh release create "$DATE" \
  $SRC_TAR \
  $SRC_TAR.intoto.jsonl \
  --title "$DATE" \
  --notes "### Installation
\`\`\`
bazel_dep(name = \"toolchains_cc\", version = \"$DATE\")
register_toolchains(\"@toolchains_cc\")
\`\`\`"
