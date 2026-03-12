# Adding a New Linux Headers Version

This runbook describes the complete process for building a new Linux kernel headers version and integrating it into the toolchain.

## Overview

Adding a new Linux headers version requires four phases:

1. **Source tarball** -- create and cache the Linux kernel source tarball
2. **Build headers** -- extract and package kernel headers for each target architecture via GitHub Actions
3. **Bazel integration** -- add the new version to the toolchain configuration with release metadata and SHA256 hashes
4. **Validation** -- verify all examples and tests build successfully with the new headers version

Linux kernel headers are a build-time dependency for both glibc and GCC. However, existing glibc sysroots and GCC binaries do **not** need to be rebuilt when adding a new headers version -- the headers are distributed independently and included in the sysroot at Bazel configuration time.

## Prerequisites

- `gh` CLI authenticated with access to the repository

## Step-by-step Procedure

### 1. Check for existing source tarball

```bash
gh release view binaries --json assets --jq '.assets[].name' | grep "linux-<VERSION>.tar.xz"
```

If the source tarball already exists (e.g., `linux-6.17.tar.xz`), skip to step 3.

### 2. Create the source tarball

Trigger the `create_source_tarballs` workflow:

```bash
gh workflow run create_source_tarballs.yml \
  -f component=linux \
  -f version=<VERSION>
```

The source is cloned from `https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git` using the `v<VERSION>` tag.

Monitor the run:

```bash
gh run list --workflow=create_source_tarballs.yml --limit=1
gh run watch <RUN_ID>
```

Verify the tarball was uploaded:

```bash
gh release view binaries --json assets --jq '.assets[].name' | grep "linux-<VERSION>.tar.xz"
```

Wait for the source tarball to be uploaded before proceeding. The header build workflows download the source tarball from the `binaries` release and will fail if it does not exist.

### 3. Check for existing header binaries

```bash
gh release view binaries --json assets --jq '.assets[].name' | grep "linux-headers-<VERSION>-"
```

If header binaries already exist for both architectures (e.g., `x86_64-linux-headers-<VERSION>-*.tar.xz` and `aarch64-linux-headers-<VERSION>-*.tar.xz`), skip to step 5.

### 4. Build Linux headers

Trigger the build workflows for each architecture:

```bash
# x86_64
gh workflow run build_linux_headers_x86_64.yml \
  -f linux_versions='["<VERSION>"]'

# aarch64
gh workflow run build_linux_headers_aarch64.yml \
  -f linux_versions='["<VERSION>"]'
```

Monitor the runs and wait for both to complete successfully before proceeding:

```bash
gh run list --workflow=build_linux_headers_x86_64.yml --limit=3
gh run list --workflow=build_linux_headers_aarch64.yml --limit=3
gh run watch <RUN_ID>
```

Verify the tarballs were uploaded:

```bash
gh release view binaries --json assets --jq '.assets[].name' | grep "linux-headers-<VERSION>-"
```

Each build produces a single tarball per architecture:
- `x86_64-linux-headers-<VERSION>-<DATE>.tar.xz`
- `aarch64-linux-headers-<VERSION>-<DATE>.tar.xz`

The build process runs `make headers_install` with the appropriate `ARCH` value (`x86` for x86_64, `arm64` for aarch64) and packages the installed headers.

### 5. Update Bazel configuration

After the builds succeed, follow the [add-toolchain-configuration](add-toolchain-configuration.md) and [update-binary-release-metadata](update-binary-release-metadata.md) runbooks to:

1. Add the new Linux headers version to `SUPPORTED_VERSIONS` in [private/config.bzl](../../private/config.bzl):

```python
"linux_headers_version": {
    "6.17": True,  # <-- new
    "6.18": True,
},
```

2. Add `RELEASE_TO_DATE` and `TARBALL_TO_SHA256` entries in [private/downloads/linux_headers.bzl](../../private/downloads/linux_headers.bzl).

3. Compute SHA256 hashes for the new tarballs:

```bash
gh release download binaries \
  --pattern "*linux-headers-<VERSION>*" \
  --dir /tmp/release-artifacts

sha256sum /tmp/release-artifacts/*.tar.xz
```

### 6. Validate all examples

Each example is its own Bazel module with `cc_toolchains.declare(name = "my_toolchain")`, so `repo_env` flags use the `my_toolchain_` prefix.

Run all examples:

```bash
for example in examples/*/; do
  echo "=== Building $(basename "$example") ==="
  (cd "$example" && bazel build \
    --repo_env=my_toolchain_linux_headers_version=<VERSION> \
    //...) || echo "FAILED: $(basename "$example")"
done
```

Also run the repo-level tests:

```bash
bazel test \
  --repo_env=toolchains_cc_dev_linux_headers_version=<VERSION> \
  //tests/...
```

The current examples are: boost, curl, fmt, gmp, googletest, grpc, libarchive, libuv, nlohmann_json, protobuf, rust_bindgen, sqlite, zlib, zstd.

## Linux Headers Version Compatibility

Linux kernel headers are backward compatible -- userspace code compiled against older headers works on newer kernels. The headers version sets the **maximum** kernel API surface available at compile time:

- Programs using only POSIX/libc APIs are unaffected by the headers version
- Programs using kernel-specific APIs (ioctls, netlink, eBPF, io_uring) may need newer headers to access new features
- The headers version does **not** set a minimum kernel requirement -- that is determined by which syscalls the program actually uses at runtime

| Version | Release date | Notable additions |
|---|---|---|
| 6.17 | 2025-03 | — |
| 6.18 | 2025-05 | — |

## Checklist

- [ ] Source tarball `linux-<VERSION>.tar.xz` exists in `binaries` release
- [ ] Header tarballs exist in `binaries` release for both x86_64 and aarch64
- [ ] `SUPPORTED_VERSIONS` updated in `private/config.bzl`
- [ ] `RELEASE_TO_DATE` updated in `private/downloads/linux_headers.bzl`
- [ ] `TARBALL_TO_SHA256` updated in `private/downloads/linux_headers.bzl`
- [ ] `bazel build //...` succeeds in each example directory with the new headers version
- [ ] `bazel test //tests/...` passes with the new headers version

## Troubleshooting

### Build workflow fails with "source tarball not found"
The Linux kernel source tarball hasn't been created yet. Run step 2 first to create it via the `create_source_tarballs` workflow.

### Key not found in `RELEASE_TO_DATE`
Verify the key format matches exactly: `{arch}-linux-headers-{version}` (e.g., `x86_64-linux-headers-6.17`). Check [private/downloads/linux_headers.bzl](../../private/downloads/linux_headers.bzl) for the expected format.

### SHA256 mismatch
Re-download the tarball and recalculate the hash. Ensure you're using the correct release artifact.

## Related Files

- [private/config.bzl](../../private/config.bzl): Configuration validation and supported versions
- [private/downloads/linux_headers.bzl](../../private/downloads/linux_headers.bzl): Linux headers download metadata
- [private/downloads/all.bzl](../../private/downloads/all.bzl): Download orchestration
- [.github/workflows/build_linux_headers_x86_64.yml](../../.github/workflows/build_linux_headers_x86_64.yml): x86_64 headers build workflow
- [.github/workflows/build_linux_headers_aarch64.yml](../../.github/workflows/build_linux_headers_aarch64.yml): aarch64 headers build workflow
- [.github/workflows/build_linux_headers/](../../.github/workflows/build_linux_headers/): Shared build scripts
- [.github/workflows/create_source_tarballs.yml](../../.github/workflows/create_source_tarballs.yml): Source tarball creation workflow
