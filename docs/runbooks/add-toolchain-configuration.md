# Adding New Toolchain Configuration

This runbook describes the complete process for adding a new toolchain configuration to toolchains_cc.

## Overview

Toolchains are defined by three parameters:
- **Target triple**: e.g., `x86_64-linux-gnu`, `x86_64-linux-musl`
- **libc version**: glibc (e.g., `2.28` to `2.42`) or musl (e.g., `1.2.5`)
- **Compiler version**: GCC version (e.g., `14.3.0`, `15.2.0`)

## Prerequisites

Before adding a new configuration:
- [ ] Verify the toolchain binaries have been built and published as a GitHub release
- [ ] Have the release URL available
- [ ] Have the SHA256 hash of the tarball ready

## Step-by-step Procedure

### 1. Update Support Matrix

Edit [private/config.bzl](../../private/config.bzl) and add an entry to the `SUPPORT_MATRIX` dictionary.

**Location**: Find the `SUPPORT_MATRIX` dictionary (around line 50+)

**Format**:
```python
SUPPORT_MATRIX = {
    # ... existing entries ...
    "x86_64-linux-gnu:2.42:gcc:15.2.0": struct(
        target = "x86_64-linux-gnu",
        libc = "glibc",
        libc_version = "2.42",
        compiler = "gcc",
        compiler_version = "15.2.0",
    ),
}
```

**Key format**: `{target}:{libc_version}:{compiler}:{compiler_version}`

### 2. Add Release Date

Edit [private/download_bins.bzl](../../private/download_bins.bzl) and add the release date mapping.

**Location**: Find the `RELEASE_TO_DATE` dictionary

**Format**:
```python
RELEASE_TO_DATE = {
    # ... existing entries ...
    "x86_64-linux-gnu-glibc-2.42-gcc-15.2.0": "2024-01-15",
}
```

**Key format**: `{target}-{libc}-{libc_version}-{compiler}-{compiler_version}`

### 3. Add SHA256 Hash

In the same file [private/download_bins.bzl](../../private/download_bins.bzl), add the SHA256 hash.

**Location**: Find the `TARBALL_TO_SHA256` dictionary

**Format**:
```python
TARBALL_TO_SHA256 = {
    # ... existing entries ...
    "x86_64-linux-gnu-glibc-2.42-gcc-15.2.0.tar.zst": "abc123def456...",
}
```

**Key format**: `{target}-{libc}-{libc_version}-{compiler}-{compiler_version}.tar.zst`

**Getting the SHA256 hash**:
```bash
# If you have the tarball locally
sha256sum x86_64-linux-gnu-glibc-2.42-gcc-15.2.0.tar.zst

# Or from GitHub releases
curl -sL https://github.com/beadss/toolchains_cc/releases/download/... | sha256sum
```

## Testing the New Configuration

After making the changes:

```bash
# Test building with the new configuration
./bazel build \
  --repo_env=toolchains_cc_target=x86_64-linux-gnu \
  --repo_env=toolchains_cc_libc_version=2.42 \
  --repo_env=toolchains_cc_compiler_version=15.2.0 \
  //tests/...

# Run tests
./bazel test \
  --repo_env=toolchains_cc_target=x86_64-linux-gnu \
  --repo_env=toolchains_cc_libc_version=2.42 \
  --repo_env=toolchains_cc_compiler_version=15.2.0 \
  //tests/...
```

## Updating CI

If this is a new configuration that should be tested in CI, update [.github/workflows/ci.yml](../../.github/workflows/ci.yml) to include it in the test matrix.

## Common Issues

### Issue: "Unsupported configuration"
**Solution**: Verify the key format exactly matches in all three locations (SUPPORT_MATRIX, RELEASE_TO_DATE, TARBALL_TO_SHA256)

### Issue: "SHA256 mismatch"
**Solution**: Re-download the tarball and recalculate the hash. Ensure you're using the correct release.

### Issue: "Release not found"
**Solution**: Verify the release exists on GitHub and the URL pattern in download_bins.bzl is correct.

## Related Files

- [private/config.bzl](../../private/config.bzl): Configuration validation and support matrix
- [private/download_bins.bzl](../../private/download_bins.bzl): Release URLs and hashes
- [private/lazy_download_bins.bzl](../../private/lazy_download_bins.bzl): Download logic
