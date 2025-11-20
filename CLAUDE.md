# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

toolchains_cc is a Bazel module that provides hermetic C/C++ toolchains and sysroots. It offers easy-to-use, hermetic toolchains for building C/C++ code with Bazel using GCC (currently only GCC support, though the architecture supports multiple compilers).

## Build System

- **Bazel version**: 8.4.2 (specified in [.bazelversion](.bazelversion))
- **Module system**: Uses Bazel's MODULE system exclusively (no WORKSPACE support)
- **Wrapper script**: Use `./bazel` instead of direct `bazel` commands

## Common Commands

### Building
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

### Testing
```bash
# Run all tests
./bazel test //...

# Run specific test
./bazel test //tests/hello_world:hello
./bazel test //tests/hello_world:hello++
```

### Linting
```bash
# Check Bazel file formatting
./bazel run :buildifier.check

# Auto-fix Bazel file formatting
./bazel run :buildifier.fix
```

## Architecture

### Two-Phase Repository Rule Design

The core architecture uses a clever two-phase approach to avoid unnecessary downloads:

1. **Eager Declaration** ([private/eager_declare_toolchain.bzl](private/eager_declare_toolchain.bzl)): Declares the toolchain metadata immediately when registered, allowing Bazel to know about the toolchain without downloading binaries.

2. **Lazy Download** ([private/lazy_download_bins.bzl](private/lazy_download_bins.bzl)): Downloads toolchain binaries and sysroots only when the toolchain is actually used for compilation.

This separation is critical for polyglot repositories where C/C++ toolchains shouldn't block Python-only builds. The module extension in [extensions.bzl](extensions.bzl) coordinates both phases.

### Configuration via Environment Variables

Toolchain configuration uses `--repo_env` flags prefixed with the toolchain name (default: `toolchains_cc_`). This approach is necessary because Bazel's repository rule phase occurs before build flags are available. See [private/config.bzl](private/config.bzl) for the full rationale.

Configuration parameters:
- `toolchains_cc_target`: Target triple (e.g., `x86_64-linux-gnu`, `x86_64-linux-musl`)
- `toolchains_cc_libc_version`: glibc version (e.g., `2.28` to `2.42`) or musl version (e.g., `1.2.5`)
- `toolchains_cc_compiler_version`: GCC version (e.g., `14.3.0`, `15.2.0`)

Default: `x86_64-linux-gnu:2.28:gcc:15.2.0`

### Support Matrix

Valid configurations are defined in [private/config.bzl](private/config.bzl) `SUPPORT_MATRIX`. Release URLs and SHA256 hashes are maintained in [private/download_bins.bzl](private/download_bins.bzl).

When adding new toolchain configurations:
1. Add entry to `SUPPORT_MATRIX` in [private/config.bzl](private/config.bzl)
2. Add release date to `RELEASE_TO_DATE` in [private/download_bins.bzl](private/download_bins.bzl)
3. Add SHA256 hash to `TARBALL_TO_SHA256` in [private/download_bins.bzl](private/download_bins.bzl)

### Key Files

- [MODULE.bazel](MODULE.bazel): Module definition and default toolchain registration
- [extensions.bzl](extensions.bzl): Module extension that instantiates both eager and lazy repo rules
- [private/config.bzl](private/config.bzl): Configuration validation and support matrix
- [private/declare_toolchain.bzl](private/declare_toolchain.bzl): cc_toolchain and cc_args setup
- [private/declare_tools.bzl](private/declare_tools.bzl): Tool map configuration for compiler, linker, archiver, etc.
- [BUILD.bazel](BUILD.bazel): Root build file with buildifier targets and toolchain alias

## CI/CD

CI runs a configuration matrix testing all supported combinations of compiler versions, libc versions, and targets. See [.github/workflows/ci.yml](.github/workflows/ci.yml):
- Tests all glibc versions (2.28-2.42) with both GCC 14.3.0 and 15.2.0
- Tests musl 1.2.5 with GCC 15.2.0
- Runs buildifier checks
- Runs commitlint for PR commits

## Release Process

Toolchain binaries are built separately and published as GitHub releases. The repository downloads these pre-built tarballs rather than building toolchains from source. Release scripts are in [.github/workflows/](/.github/workflows/).
