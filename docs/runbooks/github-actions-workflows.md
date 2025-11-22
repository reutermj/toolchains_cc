# GitHub Actions Workflows

This runbook describes best practices for creating and maintaining GitHub Actions workflows in this repository.

## Overview

GitHub Actions workflows in this repository follow specific patterns to maintain readability, testability, and debuggability. These practices help ensure workflows are maintainable and can be debugged efficiently when issues arise.

## When to Extract Logic to Shell Scripts

### Always Extract

Extract workflow logic to standalone shell scripts when:

- **The workflow contains bash commands**: Any `run:` step with multiple bash commands or complex logic should be extracted to a script
- **The logic is longer than ~10 lines**: Short inline commands are acceptable, but anything longer becomes hard to read in YAML
- **The workflow needs to be debuggable locally**: Shell scripts can be run and tested outside of GitHub Actions
- **The workflow logic might be reused**: Scripts can be called from multiple workflows or run manually

### Example: Good (Script-Based)

```yaml
jobs:
  update-bazelisk:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v6

      - name: Update Bazelisk and create PR
        env:
          GITHUB_TOKEN: ${{ github.token }}
        run: ./scripts/update-bazelisk.sh
```

### Example: Bad (Inline Bash)

```yaml
jobs:
  update-bazelisk:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v6

      - name: Update Bazelisk
        run: |
          ./bazel --update-bazelisk

      - name: Check for changes
        run: |
          if git diff --quiet tools/bazelisk-*; then
            echo "No changes"
          else
            NEW_VERSION=$(./tools/bazelisk-linux-amd64 version | head -n1 | sed 's/Bazelisk version: //')
            git config user.name "github-actions[bot]"
            git config user.email "github-actions[bot]@users.noreply.github.com"
            # ... 50+ more lines of bash in YAML ...
          fi
```

**Why is the second example bad?**
- Hard to read: Bash commands mixed with YAML syntax and indentation
- Hard to test: Can't easily run the logic locally without copying from YAML
- Hard to debug: No easy way to add logging or test individual steps
- Hard to maintain: Changes require editing YAML and managing indentation

## Script Organization

### Location

Shell scripts for workflows should be stored in subdirectories within [.github/workflows/](../../.github/workflows/):
- **Simple workflows**: [.github/workflows/workflow-name/](../../.github/workflows/) - scripts in a subdirectory matching the workflow YAML name
- **Complex workflows**: [.github/workflows/workflow-name/](../../.github/workflows/) - step scripts in a subdirectory matching the workflow YAML name

**Naming convention:**
- Workflow YAML: `.github/workflows/my-workflow.yml`
- Scripts directory: `.github/workflows/my-workflow/`
- Simple workflow script: `.github/workflows/my-workflow/my-workflow.sh`
- Complex workflow scripts: `.github/workflows/my-workflow/step-1_*`, `step-2_*`, etc.

### Script Naming

For simple workflows:
- Main script should match the workflow name: `my-workflow.sh` for `my-workflow.yml`
- Use kebab-case matching the workflow YAML name
- Always use `.sh` extension

For complex workflows:
- Use numbered step format: `step-1_description`, `step-2_description`, etc.
- Use snake_case for the description part after the number
- No `.sh` extension on step scripts (following the GCC build pattern)

### Script Organization Principles

**Split workflows into multiple small scripts, not one large script with functions.**

Each distinct logical step should be its own script file. The workflow YAML or Dockerfile sequences these steps.

#### Simple Workflows (Few Steps)

For simple workflows with 2-3 linear steps, a single script is acceptable:

```bash
#!/bin/bash
set -euox pipefail

# Simple linear script - no functions needed
./bazel --update-bazelisk

if git diff --quiet tools/bazelisk-*; then
  echo "No changes detected"
  exit 0
fi

NEW_VERSION=$(./tools/bazelisk-linux-amd64 version | head -n1 | sed 's/Bazelisk version: //')
git checkout -b "update-${NEW_VERSION}"
git add tools/bazelisk-*
git commit -m "Update to ${NEW_VERSION}"
git push origin "update-${NEW_VERSION}"
```

**Key elements:**
- Shebang: `#!/bin/bash`
- Error handling: `set -euox pipefail`
  - `-e`: Exit on error
  - `-u`: Error on undefined variables
  - `-o pipefail`: Exit on pipe failures
  - `-x`: Print commands (helpful for debugging in CI logs)
- No functions for simple linear logic
- Exit early when appropriate

#### Complex Workflows (Many Steps)

For complex workflows, split into numbered step scripts sequenced by the workflow:

**Directory structure:**
```
.github/workflows/
├── build-toolchain.yml          # Workflow YAML (must be in .github/workflows/)
└── build-toolchain/             # Scripts subdirectory (matches YAML name)
    ├── environment              # Shared environment variables
    ├── step-1_install_deps      # Individual step scripts
    ├── step-2_download_source
    ├── step-3_configure
    ├── step-4_build
    └── step-5_package
```

**Workflow YAML:**
```yaml
env:
  SCRIPTS_DIR: ${{ github.workspace }}/.github/workflows/build-toolchain

jobs:
  build:
    steps:
      - uses: actions/checkout@v6
      - name: Install Dependencies
        run: $SCRIPTS_DIR/step-1_install_deps
      - name: Download Source
        run: $SCRIPTS_DIR/step-2_download_source
      - name: Configure
        run: $SCRIPTS_DIR/step-3_configure
      - name: Build
        run: $SCRIPTS_DIR/step-4_build
      - name: Package
        run: $SCRIPTS_DIR/step-5_package
```

**Shared environment file:**
```bash
#!/bin/bash
set -euox pipefail

# Shared variables for all steps
export WORK_DIR="/tmp/work"
export OUTPUT_DIR="/tmp/output"

mkdir -p "$WORK_DIR"
mkdir -p "$OUTPUT_DIR"

# Export to GitHub Actions environment if running in CI
if [ -n "${GITHUB_ENV:-}" ]; then
    echo "WORK_DIR=$WORK_DIR" >> "$GITHUB_ENV"
    echo "OUTPUT_DIR=$OUTPUT_DIR" >> "$GITHUB_ENV"
fi
```

**Individual step script:**
```bash
#!/bin/bash
set -euox pipefail
source ${SCRIPTS_DIR}/environment

# Step-specific logic - simple and focused
apt update
apt install -y build-essential wget curl
```

**Benefits of this approach:**
- Each step is self-contained and easy to understand
- Steps can be tested individually: `./step-3_configure`
- Docker layer caching works per-step
- Easy to add/remove/reorder steps in the workflow
- GitHub Actions UI shows clear step names and timing
- No complex function hierarchies to navigate

### Make Scripts Executable

Always make scripts executable:

```bash
chmod +x .github/workflows/my-workflow/my-workflow.sh
chmod +x .github/workflows/build-toolchain/step-*
```

Commit the executable permission to git - it will be preserved.

## When to Create a Dockerfile

### Create a Dockerfile When

Dockerfiles for workflow testing should be created when:

- **The workflow is complex and long**: Multi-step workflows that take significant time to run
- **The workflow requires specific dependencies**: When the workflow needs specific tools, packages, or environment setup
- **Debugging requires iteration**: When you need to debug a particular step and want to reuse cached previous steps
- **Reproducibility is important**: When you need to exactly reproduce the CI environment locally
- **Source code downloading takes time**: Docker layer caching helps avoid re-downloading on each test

### Example: When a Dockerfile is Helpful

For workflows like building toolchains:

```dockerfile
# .github/workflows/build-toolchain.dockerfile
FROM ubuntu:24.04

# Install build dependencies (cached layer)
RUN apt-get update && apt-get install -y \
  build-essential \
  wget \
  git \
  && rm -rf /var/lib/apt/lists/*

# Download source code (cached layer)
WORKDIR /build
RUN wget https://example.com/large-source.tar.gz && \
  tar xzf large-source.tar.gz

# Copy build script (invalidates cache from here)
COPY scripts/build-toolchain.sh .
RUN ./build-toolchain.sh
```

**Benefits:**
- long steps are cached and reused across test runs
- Dependency installation is cached
- You can test individual steps: `docker build --target=intermediate-stage`
- Exact environment reproduction: Same OS, same packages, same versions

### Don't Create a Dockerfile When

Skip the Dockerfile for workflows that are:

- **Simple and fast**: Single-step workflows or workflows that complete quickly
- **Using existing actions**: Workflows primarily composed of GitHub Actions marketplace actions
- **Not compute-intensive**: Workflows that don't involve compilation, downloading large files, or complex setup
- **Easy to debug**: When the workflow logic is straightforward and errors are obvious

### Example: When a Dockerfile is NOT Needed

For the Bazelisk update workflow:

```yaml
jobs:
  update-bazelisk:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - run: ./scripts/update-bazelisk.sh
```

**Why no Dockerfile needed:**
- Simple: Single script execution
- Fast: Completes in seconds
- Standard environment: Uses GitHub's ubuntu-latest which has all needed tools
- Easy to debug: Script can be run locally without special setup

## Testing Workflows Locally

### Testing Shell Scripts

Shell scripts can be tested directly:

```bash
# Test the script locally
./scripts/update-bazelisk.sh

# Test with dry-run environment variables
DRY_RUN=true ./scripts/update-bazelisk.sh

# Test individual functions (if exported)
bash -c 'source ./scripts/update-bazelisk.sh; check_prerequisites'
```

### Testing with act

For testing complete workflows locally, use [act](https://github.com/nektos/act):

```bash
# Install act
brew install act  # macOS
# or
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run a workflow
act -j update-bazelisk

# Run with secrets
act -j update-bazelisk -s GITHUB_TOKEN=ghp_xxx

# Run specific event
act workflow_dispatch
```

### Testing with Docker

When a Dockerfile exists for the workflow:

```bash
# Build the Docker image
docker build -f .github/workflows/build-toolchain.dockerfile -t test-workflow .

# Run interactively to debug
docker run -it test-workflow bash

# Run specific step
docker build --target=build-stage -f .github/workflows/build-toolchain.dockerfile .

# Use build cache to speed up iterations
docker build --cache-from test-workflow:latest -f .github/workflows/build-toolchain.dockerfile .
```

## Workflow Script Checklist

Before committing a new workflow or script, verify:

### General
- [ ] Complex bash logic is extracted to shell scripts (not inline in YAML)
- [ ] Workflow YAML is clean and readable (primarily action uses and script calls)
- [ ] Dockerfile is created only if workflow is complex/long and reproducibility matters

### Script Organization
- [ ] Simple workflows (2-3 steps): Use a single linear script, no functions
- [ ] Complex workflows (4+ steps): Split into numbered step scripts (step-1_*, step-2_*, etc.)
- [ ] Complex workflows: Create an `environment` file for shared variables
- [ ] Scripts are located in `.github/workflows/<workflow-name>/` subdirectory
- [ ] Script directory name matches the workflow YAML name (e.g., `my-workflow.yml` → `my-workflow/`)

### Script Quality
- [ ] Each script has shebang (`#!/bin/bash`) and error handling (`set -euox pipefail`)
- [ ] Scripts that use shared variables: `source ${SCRIPTS_DIR}/environment`
- [ ] Scripts have descriptive names using kebab-case (or step-N_description format)
- [ ] Scripts are executable (`chmod +x`)
- [ ] Scripts can be tested locally outside of GitHub Actions
- [ ] Scripts include helpful logging (the `-x` flag prints commands automatically)

## Common Patterns

### Pattern: Check for Changes Before Proceeding

```bash
if git diff --quiet path/to/files; then
  echo "No changes detected"
  exit 0
fi

echo "Changes detected, proceeding..."
# ... rest of script
```

### Pattern: Get Version from Command Output

```bash
NEW_VERSION=$(./binary --version | head -n1 | sed 's/Version: //')
echo "Detected version: $NEW_VERSION"
```

### Pattern: Create Branch, Commit, Push, PR

```bash
BRANCH_NAME="update-${VERSION}"

git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"

git checkout -b "$BRANCH_NAME"
git add path/to/files
git commit -m "commit message"
git push origin "$BRANCH_NAME"

gh pr create \
  --title "Title" \
  --body "Body" \
  --base main \
  --head "$BRANCH_NAME"
```

### Pattern: Exit Early on No-Op

```bash
# Do initial work
download_files

# Exit early if nothing changed
if [[ "$CHANGED" == "false" ]]; then
  echo "No changes needed"
  exit 0
fi

# Only proceed if there's work to do
process_changes
create_pr
```

### Pattern: Shared Environment Variables Across Steps

```bash
# In environment file
#!/bin/bash
set -euox pipefail

export WORK_DIR="/tmp/work"
export OUTPUT_DIR="/tmp/output"

mkdir -p "$WORK_DIR" "$OUTPUT_DIR"

# Make available to subsequent GitHub Actions steps
if [ -n "${GITHUB_ENV:-}" ]; then
    echo "WORK_DIR=$WORK_DIR" >> "$GITHUB_ENV"
    echo "OUTPUT_DIR=$OUTPUT_DIR" >> "$GITHUB_ENV"
fi
```

```bash
# In step scripts
#!/bin/bash
set -euox pipefail
source ${SCRIPTS_DIR}/environment

# Use the shared variables
cd "$WORK_DIR"
process_files
mv output/* "$OUTPUT_DIR/"
```

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [act - Run GitHub Actions locally](https://github.com/nektos/act)
- [Bash Best Practices](https://bertvv.github.io/cheat-sheets/Bash.html)
- [Shell Script Template](https://betterdev.blog/minimal-safe-bash-script-template/)

## Examples in This Repository

### Simple Workflows (Single Script)

**update-bazelisk workflow:**
- Workflow: [.github/workflows/update-bazelisk.yml](../../.github/workflows/update-bazelisk.yml)
- Script: [.github/workflows/update-bazelisk/update-bazelisk.sh](../../.github/workflows/update-bazelisk/update-bazelisk.sh)
- Pattern: Simple linear script with no functions

**publish workflow:**
- Workflow: [.github/workflows/publish.yml](../../.github/workflows/publish.yml)
- Script: [.github/workflows/publish/publish.sh](../../.github/workflows/publish/publish.sh)
- Pattern: Simple script for creating GitHub releases

### Complex Workflows (Multiple Step Scripts)

**build_gcc workflow:**
- Workflow: [.github/workflows/build_gcc.yml](../../.github/workflows/build_gcc.yml)
- Scripts directory: [.github/workflows/build_gcc/](../../.github/workflows/build_gcc/)
  - `environment`: Shared environment variables
  - `step-1_install_dependencies`: Install build dependencies
  - `step-2_build_crosstool_ng`: Build crosstool-NG
  - `step-3_configure_toolchain`: Configure toolchain settings
  - `step-4_build_toolchain`: Compile the toolchain
  - `step-5_package_toolchain`: Package artifacts
  - `step-6_upload_release`: Upload to GitHub releases
- Pattern: 6 distinct step scripts sequenced by the workflow YAML

**build_llvm workflow:**
- Workflow: [.github/workflows/build_llvm.yml](../../.github/workflows/build_llvm.yml)
- Scripts directory: [.github/workflows/build_llvm/](../../.github/workflows/build_llvm/)
- Pattern: Multi-step build process for LLVM/Clang toolchain
