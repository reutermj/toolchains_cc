#!/bin/bash
set -euox pipefail

DATE=$(date +'%Y.%-m.%-d')
SRC_TAR="toolchains_cc-$DATE.tar.gz"
git archive --format=tar.gz --output=$SRC_TAR main
gh release create "$DATE" \
  $SRC_TAR \
  --title "$DATE" \
  --notes "### Installation
\`\`\`
bazel_dep(name = \"toolchains_cc\", version = \"$DATE\")
register_toolchains(\"@toolchains_cc\")
\`\`\`"

# Output the tag for the workflow
echo "tag=$DATE" >> $GITHUB_OUTPUT
echo "release_source_tarball=$SRC_TAR" >> $GITHUB_ENV
