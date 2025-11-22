# toolchains_cc 

**BEFORE ANYTHING ELSE**: Run `bd onboard` and follow the instructions to set up the beads development environment.

## Runbooks

Runbooks are detaild procedures for use in a specific context. 
**When a runbook's context occurs, YOU MUST ALWAYS read the runbook BEFORE taking any action.**

- **BEFORE creating any commit, YOU MUST read**: [docs/runbooks/commit-message-guidelines.md](docs/runbooks/commit-message-guidelines.md)
- **BEFORE adding new toolchain configurations, YOU MUST read**: [docs/runbooks/add-toolchain-configuration.md](docs/runbooks/add-toolchain-configuration.md)
- **BEFORE creating or modifying GitHub Actions workflows, YOU MUST read**: [docs/runbooks/github-actions-workflows.md](docs/runbooks/github-actions-workflows.md)

## Building

Use the `./bazel` wrapper script instead of `bazel`

```bash
# Build everything with default toolchain (gcc 15.2.0, glibc 2.28, x86_64-linux-gnu)
./bazel build //...

# Build with specific toolchain configuration
./bazel build \
  --repo_env=toolchains_cc_target=x86_64-linux-gnu \
  --repo_env=toolchains_cc_libc_version=2.39 \
  --repo_env=toolchains_cc_compiler_version=15.2.0 \
  //...

# Build tests
./bazel build //tests/...
```

## Testing
```bash
# Run all tests
./bazel test //...

# Run specific test
./bazel test //tests/hello_world:hello
./bazel test //tests/hello_world:hello++
```

## Linting
```bash
# Check Bazel file formatting
./bazel run :buildifier.check

# Auto-fix Bazel file formatting
./bazel run :buildifier.fix
```
