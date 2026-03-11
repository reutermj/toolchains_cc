# Adding a New glibc Version

This runbook describes the complete process for building a new glibc version and integrating it into the toolchain.

## Overview

Adding a new glibc version requires four phases:

1. **Source tarball** -- create and cache the glibc source tarball
2. **Build glibc sysroots** -- build glibc for each target architecture via GitHub Actions
3. **Bazel integration** -- add the new version to the toolchain configuration with release metadata and SHA256 hashes
4. **Validation** -- verify all examples and tests build successfully with the new glibc version

GCC binaries do not need to be rebuilt. The existing GCC binaries are built against a baseline glibc (2.28) and work with any compatible glibc sysroot via `--sysroot`.

## Prerequisites

- `gh` CLI authenticated with access to the repository
- Linux kernel headers must already exist in the `binaries` release (the glibc build downloads them)
- A bootstrap GCC must already exist in the `binaries` release (the glibc build uses it for compilation)

## Step-by-step Procedure

### 1. Check for existing source tarball

```bash
gh release view binaries --json assets --jq '.assets[].name' | grep "glibc-<VERSION>.tar.xz"
```

If the source tarball already exists (e.g., `glibc-2.29.tar.xz`), skip to step 3.

### 2. Create the source tarball

Trigger the `create_source_tarballs` workflow:

```bash
gh workflow run create_source_tarballs.yml \
  -f component=glibc \
  -f version=<VERSION>
```

Monitor the run:

```bash
gh run list --workflow=create_source_tarballs.yml --limit=1
gh run watch <RUN_ID>
```

Verify the tarball was uploaded:

```bash
gh release view binaries --json assets --jq '.assets[].name' | grep "glibc-<VERSION>.tar.xz"
```

Wait for the source tarball to be uploaded before proceeding. The glibc build workflows download the source tarball from the `binaries` release and will fail if it does not exist.

### 3. Check for existing glibc sysroot binaries

```bash
gh release view binaries --json assets --jq '.assets[].name' | grep "glibc-<VERSION>-"
```

If sysroot binaries already exist for both architectures (e.g., `x86_64-linux-gnu-glibc-<VERSION>-*.tar.xz` and `aarch64-linux-gnu-glibc-<VERSION>-*.tar.xz`), skip to step 5.

### 4. Build glibc sysroots

Trigger the build workflows for each architecture:

```bash
# x86_64
gh workflow run build_glibc_x86_64.yml \
  -f glibc_versions='["<VERSION>"]'

# aarch64
gh workflow run build_glibc_aarch64.yml \
  -f glibc_versions='["<VERSION>"]'
```

Monitor the runs and wait for both to complete successfully before proceeding:

```bash
gh run list --workflow=build_glibc_x86_64.yml --limit=3
gh run list --workflow=build_glibc_aarch64.yml --limit=3
gh run watch <RUN_ID>
```

Verify the tarballs were uploaded:

```bash
gh release view binaries --json assets --jq '.assets[].name' | grep "glibc-<VERSION>-"
```

Each build produces a single tarball per architecture:
- `x86_64-linux-gnu-glibc-<VERSION>-<DATE>.tar.xz`
- `aarch64-linux-gnu-glibc-<VERSION>-<DATE>.tar.xz`

### 5. Update Bazel configuration

After the builds succeed, follow the [add-toolchain-configuration](add-toolchain-configuration.md) and [update-binary-release-metadata](update-binary-release-metadata.md) runbooks to:

1. Add the new glibc version to `SUPPORTED_VERSIONS` in [private/config.bzl](../../private/config.bzl):

```python
"libc_version": {
    "1.2.5": True,
    "2.28": True,
    "<VERSION>": True,  # <-- new
},
```

2. Add `RELEASE_TO_DATE` and `TARBALL_TO_SHA256` entries in [private/downloads/glibc.bzl](../../private/downloads/glibc.bzl).

3. Compute SHA256 hashes for the new tarballs:

```bash
gh release download binaries \
  --pattern "*glibc-<VERSION>*" \
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
    --repo_env=my_toolchain_target=x86_64-linux-gnu \
    --repo_env=my_toolchain_libc_version=<VERSION> \
    --repo_env=my_toolchain_compiler_version=15.2.0 \
    //...) || echo "FAILED: $(basename "$example")"
done
```

Also run the repo-level tests:

```bash
bazel test \
  --repo_env=toolchains_cc_dev_target=x86_64-linux-gnu \
  --repo_env=toolchains_cc_dev_libc_version=<VERSION> \
  --repo_env=toolchains_cc_dev_compiler_version=15.2.0 \
  //tests/...
```

The current examples are: boost, curl, fmt, gmp, googletest, grpc, libarchive, libuv, nlohmann_json, protobuf, rust_bindgen, sqlite, zlib, zstd.

## glibc Version Compatibility

glibc maintains strong backward compatibility — binaries built against an older glibc run on systems with a newer glibc. The version you choose sets the **minimum** glibc requirement for produced binaries:

| glibc version | First appeared in |
|---|---|
| 2.28 | Debian 10 (Buster), RHEL 8 |
| 2.29 | Ubuntu 19.04 |
| 2.30 | Ubuntu 19.10 |
| 2.31 | Debian 11 (Bullseye), Ubuntu 20.04 |
| 2.34 | RHEL 9 |
| 2.35 | Ubuntu 22.04 |
| 2.36 | Debian 12 (Bookworm) |
| 2.39 | Ubuntu 24.04 |

## Checklist

- [ ] Source tarball `glibc-<VERSION>.tar.xz` exists in `binaries` release
- [ ] glibc sysroot tarballs exist in `binaries` release for both x86_64 and aarch64
- [ ] `SUPPORTED_VERSIONS` updated in `private/config.bzl`
- [ ] `RELEASE_TO_DATE` updated in `private/downloads/glibc.bzl`
- [ ] `TARBALL_TO_SHA256` updated in `private/downloads/glibc.bzl`
- [ ] `bazel build //...` succeeds in each example directory with the new glibc version
- [ ] `bazel test //tests/...` passes with the new glibc version

## Troubleshooting

### Build workflow fails with "no asset found matching pattern 'glibc-\<VERSION\>'"
The glibc source tarball hasn't been created yet. Run step 2 first to create it via the `create_source_tarballs` workflow.

### Build workflow fails with "bootstrap GCC not found"
The glibc build requires a bootstrap GCC to compile. Ensure a bootstrap GCC exists in the `binaries` release for the target architecture. See the [build-new-gcc-version](build-new-gcc-version.md) runbook.

### Build workflow fails with "Linux headers not found"
The glibc build requires Linux kernel headers. Ensure they exist in the `binaries` release.

### Key not found in `RELEASE_TO_DATE`
Verify the key format matches exactly: `{target}-glibc-{version}` (e.g., `x86_64-linux-gnu-glibc-2.29`). Check [private/downloads/glibc.bzl](../../private/downloads/glibc.bzl) for the expected format.

### SHA256 mismatch
Re-download the tarball and recalculate the hash. Ensure you're using the correct release artifact.

## Related Files

- [private/config.bzl](../../private/config.bzl): Configuration validation and supported versions
- [private/downloads/glibc.bzl](../../private/downloads/glibc.bzl): glibc download metadata
- [private/downloads/all.bzl](../../private/downloads/all.bzl): Download orchestration
- [.github/workflows/build_glibc_x86_64.yml](../../.github/workflows/build_glibc_x86_64.yml): x86_64 glibc build workflow
- [.github/workflows/build_glibc_aarch64.yml](../../.github/workflows/build_glibc_aarch64.yml): aarch64 glibc build workflow
- [.github/workflows/build_glibc/](../../.github/workflows/build_glibc/): Shared build scripts
