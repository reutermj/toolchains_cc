# Adding New Toolchain Configuration

This runbook describes the complete process for adding a new toolchain configuration to toolchains_cc.

## Overview

Toolchains are defined by these parameters:
- **Target triple**: e.g., `x86_64-linux-gnu`, `aarch64-linux-gnu`, `x86_64-linux-musl`
- **libc version**: glibc (e.g., `2.28`) or musl (e.g., `1.2.5`)
- **Compiler version**: GCC version (e.g., `15.2.0`) or LLVM version (e.g., `21.1.1`)

The host platform is derived from the target triple (only native builds are supported).

## Prerequisites

Before adding a new configuration:
- [ ] Verify the toolchain binaries have been built and published to the [`binaries` GitHub release](https://github.com/reutermj/toolchains_cc/releases/tag/binaries)
- [ ] Have the SHA256 hashes of all required tarballs ready

## Step-by-step Procedure

### 1. Update Supported Versions

Edit [private/config.bzl](../../private/config.bzl) and add entries to the `SUPPORTED_VERSIONS` dictionary.

Add the new value to the appropriate key (e.g., `"target"`, `"libc_version"`, `"compiler_version"`):

```python
SUPPORTED_VERSIONS = {
    "target": {
        "x86_64-linux-gnu": True,
        "aarch64-linux-gnu": True,  # <-- new target
    },
    # ... other keys ...
}
```

### 2. Add Release Metadata to Download Files

Each component has its own file in [private/downloads/](../../private/downloads/):

| Component     | File                                                              |
|---------------|-------------------------------------------------------------------|
| GCC           | [private/downloads/gcc.bzl](../../private/downloads/gcc.bzl)           |
| glibc         | [private/downloads/glibc.bzl](../../private/downloads/glibc.bzl)       |
| musl          | [private/downloads/musl.bzl](../../private/downloads/musl.bzl)         |
| binutils      | [private/downloads/binutils.bzl](../../private/downloads/binutils.bzl) |
| Linux headers | [private/downloads/linux_headers.bzl](../../private/downloads/linux_headers.bzl) |
| LLVM          | [private/downloads/llvm.bzl](../../private/downloads/llvm.bzl)         |

For each affected component, add entries to both `RELEASE_TO_DATE` and `TARBALL_TO_SHA256`. See the [update-binary-release-metadata runbook](update-binary-release-metadata.md) for the exact key formats and procedure.

### 3. Update Platform Constraints (if adding a new architecture)

If this is a new CPU architecture (not just a new version), update [private/declare_toolchain.bzl](../../private/declare_toolchain.bzl):

Add the architecture to `_TARGET_TO_CPU_CONSTRAINT`:

```python
_TARGET_TO_CPU_CONSTRAINT = {
    "x86_64": "@platforms//cpu:x86_64",
    "aarch64": "@platforms//cpu:aarch64",
}
```

**Getting the SHA256 hash**:
```bash
# Download from GitHub release
gh release download binaries \
  --pattern "<tarball-name>" \
  --dir /tmp/release-artifacts

# Compute the SHA256 hash
sha256sum /tmp/release-artifacts/<tarball-name>
```

## Testing the New Configuration

Each example is its own Bazel module. The `repo_env` flag format is `{toolchain_name}_{var_name}`, where the toolchain name comes from the `cc_toolchains.declare(name = ...)` tag in each example's `MODULE.bazel`. The examples all use `name = "my_toolchain"`.

```bash
for example in examples/*/; do
  (cd "$example" && bazel build \
    --repo_env=my_toolchain_target=<target> \
    --repo_env=my_toolchain_libc_version=<libc_version> \
    --repo_env=my_toolchain_compiler_version=<compiler_version> \
    //...)
done
```

## Common Issues

### Issue: "Unsupported {key}={value}"
**Solution**: Verify the value is added to `SUPPORTED_VERSIONS` in [private/config.bzl](../../private/config.bzl).

### Issue: Key not found in `RELEASE_TO_DATE`
**Solution**: Verify the key format matches exactly. Check the download function in the relevant `.bzl` file to see the expected key format.

### Issue: "SHA256 mismatch"
**Solution**: Re-download the tarball and recalculate the hash. Ensure you're using the correct release.

## Related Files

- [private/config.bzl](../../private/config.bzl): Configuration validation and supported versions
- [private/downloads/](../../private/downloads/): Individual download files per component
- [private/downloads/constants.bzl](../../private/downloads/constants.bzl): Base URL and `get_host` helper
- [private/declare_toolchain.bzl](../../private/declare_toolchain.bzl): Toolchain declaration with platform constraints
- [private/eager_declare_toolchain.bzl](../../private/eager_declare_toolchain.bzl): Eagerly declares toolchain metadata
- [private/lazy_download_bins.bzl](../../private/lazy_download_bins.bzl): Lazily downloads binaries when needed
