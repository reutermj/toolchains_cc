# Building a New GCC Version

This runbook describes the complete process for building a new GCC version and integrating it into the toolchain.

## Overview

Building a new GCC version requires four phases:

1. **Source tarball** -- create and cache the GCC source tarball
2. **Bootstrap GCC** -- build a minimal C-only compiler
3. **Full GCC** -- build the complete C/C++ compiler using the bootstrap
4. **Bazel integration** -- add the new version to the toolchain configuration

The bootstrap compiler is needed because the full GCC build requires a GCC that targets the exact triplet. The bootstrap provides this, and the full build uses it along with the pre-existing libc (glibc or musl) to produce the final compiler.

## Prerequisites

- `gh` CLI authenticated with access to the repository
- The following dependency source tarballs must already exist in the `binaries` release: GMP, MPFR, ISL, MPC, Linux headers
- For full (non-bootstrap) builds: pre-built libc (glibc or musl) for the target must exist in the `binaries` release

## Step-by-step Procedure

### 1. Check for existing source tarball

```bash
gh release view binaries --json assets --jq '.assets[].name' | grep "gcc-<VERSION>.tar.xz"
```

If the source tarball already exists (e.g., `gcc-14.2.0.tar.xz`), skip to step 3.

### 2. Create the source tarball

Trigger the `create_source_tarballs` workflow:

```bash
gh workflow run create_source_tarballs.yml \
  -f component=gcc \
  -f version=<VERSION>
```

Monitor the run:

```bash
gh run list --workflow=create_source_tarballs.yml --limit=1
gh run watch <RUN_ID>
```

Verify the tarball was uploaded:

```bash
gh release view binaries --json assets --jq '.assets[].name' | grep "gcc-<VERSION>.tar.xz"
```

### 3. Build bootstrap GCC

The bootstrap build produces a C-only compiler used to compile the final GCC. It uses the host system's GCC and does not require libc or a prior GCC installation.

For each target architecture, trigger the appropriate workflow:

```bash
# x86_64
gh workflow run build_gcc_x86_64.yml \
  -f gcc_versions='["<VERSION>"]' \
  -f target=x86_64-bootstrap-linux-gnu

# aarch64
gh workflow run build_gcc_aarch64.yml \
  -f gcc_versions='["<VERSION>"]' \
  -f target=aarch64-bootstrap-linux-gnu
```

For musl targets, use `*-bootstrap-linux-musl` instead of `*-bootstrap-linux-gnu`.

Monitor the run:

```bash
gh run list --workflow=build_gcc_x86_64.yml --limit=3
gh run watch <RUN_ID>
```

Wait for the bootstrap build to complete successfully before proceeding.

### 4. Build full GCC

The full build produces the complete C/C++ compiler. It requires the bootstrap GCC from step 3 and a pre-existing libc in the `binaries` release.

```bash
# x86_64
gh workflow run build_gcc_x86_64.yml \
  -f gcc_versions='["<VERSION>"]' \
  -f target=x86_64-linux-gnu

# aarch64
gh workflow run build_gcc_aarch64.yml \
  -f gcc_versions='["<VERSION>"]' \
  -f target=aarch64-linux-gnu
```

Monitor the run:

```bash
gh run list --workflow=build_gcc_x86_64.yml --limit=3
gh run watch <RUN_ID>
```

The full build produces two tarballs per target:
- **Bins**: `<host>-<target>-gcc-<VERSION>-<DATE>.tar.xz` (compiler binaries)
- **Libs**: `<target>-gcc-lib-<VERSION>-<DATE>.tar.xz` (runtime libraries)

### 5. Update Bazel configuration

After the full build succeeds, follow the [add-toolchain-configuration](add-toolchain-configuration.md) and [update-binary-release-metadata](update-binary-release-metadata.md) runbooks to:

1. Add the new GCC version to `SUPPORTED_VERSIONS` in [private/config.bzl](../../private/config.bzl)
2. Add `RELEASE_TO_DATE` and `TARBALL_TO_SHA256` entries in [private/downloads/gcc.bzl](../../private/downloads/gcc.bzl)
3. Compute SHA256 hashes for the new tarballs:

```bash
gh release download binaries \
  --pattern "*<target>-gcc-*<VERSION>*" \
  --dir /tmp/release-artifacts

sha256sum /tmp/release-artifacts/*.tar.xz
```

### 6. Validate all examples

After updating the Bazel configuration, verify every example builds successfully with the new GCC version. Each example is its own Bazel module with `cc_toolchains.declare(name = "my_toolchain")`, so `repo_env` flags use the `my_toolchain_` prefix.

Run all examples:

```bash
for example in examples/*/; do
  echo "=== Building $(basename "$example") ==="
  (cd "$example" && bazel build \
    --repo_env=my_toolchain_compiler_version=<VERSION> \
    --repo_env=my_toolchain_target=<TARGET> \
    --repo_env=my_toolchain_libc_version=<LIBC_VERSION> \
    //...) || echo "FAILED: $(basename "$example")"
done
```

For example, to validate GCC 14.2.0 with x86_64-linux-gnu and glibc 2.28:

```bash
for example in examples/*/; do
  echo "=== Building $(basename "$example") ==="
  (cd "$example" && bazel build \
    --repo_env=my_toolchain_compiler_version=14.2.0 \
    --repo_env=my_toolchain_target=x86_64-linux-gnu \
    --repo_env=my_toolchain_libc_version=2.28 \
    //...) || echo "FAILED: $(basename "$example")"
done
```

Also run the repo-level tests:

```bash
bazel test \
  --repo_env=toolchains_cc_dev_compiler_version=<VERSION> \
  --repo_env=toolchains_cc_dev_target=<TARGET> \
  --repo_env=toolchains_cc_dev_libc_version=<LIBC_VERSION> \
  //tests/...
```

**Note on musl targets**: musl-linked binaries cannot execute on a glibc host, so `bazel test` will fail with exit code 127 ("required file not found"). For musl targets, use `bazel build //tests/...` instead to verify compilation succeeds. This is expected behavior, not a build failure.

**Known example failures with musl**: The grpc, protobuf, and rust_bindgen examples have pre-existing build failures with musl targets (related to exec-platform tool binaries, not GCC). Verify these also fail with other GCC versions on musl before investigating.

The current examples are: boost, curl, fmt, gmp, googletest, grpc, libarchive, libuv, nlohmann_json, protobuf, rust_bindgen, sqlite, zlib, zstd.

## Target naming reference

| Build type | x86_64 glibc target | x86_64 musl target |
|---|---|---|
| Bootstrap | `x86_64-bootstrap-linux-gnu` | `x86_64-bootstrap-linux-musl` |
| Full | `x86_64-linux-gnu` | `x86_64-linux-musl` |

| Build type | aarch64 glibc target | aarch64 musl target |
|---|---|---|
| Bootstrap | `aarch64-bootstrap-linux-gnu` | `aarch64-bootstrap-linux-musl` |
| Full | `aarch64-linux-gnu` | `aarch64-linux-musl` |

## Checklist

- [ ] Source tarball `gcc-<VERSION>.tar.xz` exists in `binaries` release
- [ ] Bootstrap GCC build completed successfully
- [ ] Full GCC build completed successfully (produces bins + libs tarballs)
- [ ] `SUPPORTED_VERSIONS` updated in `private/config.bzl`
- [ ] `RELEASE_TO_DATE` updated in `private/downloads/gcc.bzl`
- [ ] `TARBALL_TO_SHA256` updated in `private/downloads/gcc.bzl`
- [ ] `bazel build //...` succeeds in each example directory with the new version (see known musl failures above)
- [ ] `bazel test //tests/...` passes with the new version (for musl targets, use `bazel build` instead -- see note above)

## Troubleshooting

### Bootstrap build fails with "source tarball not found"
The GCC source tarball hasn't been created yet. Run step 2 first.

### Full build fails with "bootstrap GCC not found"
The bootstrap build hasn't completed or failed. Check step 3 completed successfully. The full build downloads the bootstrap GCC matching the same version from the `binaries` release.

### Full build fails with "libc not found"
The target's libc (glibc or musl) hasn't been built for this target. Build libc first using the appropriate workflow before attempting the full GCC build.
