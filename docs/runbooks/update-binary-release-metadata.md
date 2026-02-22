# Updating Binary Release Metadata

This runbook describes the procedure for updating `RELEASE_TO_DATE` and `TARBALL_TO_SHA256` entries in the download files after a toolchain component has been rebuilt.

## When to Use

Use this runbook when a toolchain component (GCC, glibc, binutils, Linux headers, etc.) has been rebuilt due to changes in the build process and the new artifacts have been uploaded to the `binaries` GitHub release.

## Overview

Each download file in [private/downloads/](../../private/downloads/) contains two dictionaries that tie a logical release name to a dated tarball with a verified hash:

- **`RELEASE_TO_DATE`**: Maps a release name (e.g., `x86_64-linux-x86_64-linux-gnu-gcc-15.2.0`) to a date string (e.g., `20260218`). The date is embedded in tarball filenames to distinguish rebuilds.
- **`TARBALL_TO_SHA256`**: Maps a full tarball filename (which includes the date) to its SHA256 hash. Used by Bazel's `download_and_extract` to verify integrity.

## Prerequisites

- [ ] The rebuilt artifacts have been uploaded to the [`binaries` GitHub release](https://github.com/reutermj/toolchains_cc/releases/tag/binaries)
- [ ] You know which component was rebuilt and which target/version is affected

## Step-by-step Procedure

### 1. Identify the affected download file

Each component has its own file in [private/downloads/](../../private/downloads/):

| Component     | File                                                              |
|---------------|-------------------------------------------------------------------|
| GCC           | [private/downloads/gcc.bzl](../../private/downloads/gcc.bzl)           |
| glibc         | [private/downloads/glibc.bzl](../../private/downloads/glibc.bzl)       |
| binutils      | [private/downloads/binutils.bzl](../../private/downloads/binutils.bzl) |
| Linux headers | [private/downloads/linux_headers.bzl](../../private/downloads/linux_headers.bzl) |

### 2. Find the new artifacts in the GitHub release

List assets in the `binaries` release and filter for the component you rebuilt:

```bash
gh release view binaries --json assets --jq '.assets[] | .name' | grep <component>
```

For example, after rebuilding GCC 15.2.0 for `x86_64-linux-gnu`:

```bash
gh release view binaries --json assets --jq '.assets[] | .name' | grep x86_64-linux-gnu-gcc
```

Look for artifacts with the **new date** (e.g., `20260222`) alongside the old date (e.g., `20260218`). GCC produces two tarballs per configuration:

- **Bins tarball**: `x86_64-linux-{target}-gcc-{version}-{date}.tar.xz` (compiler binaries)
- **Libs tarball**: `{target}-gcc-lib-{version}-{date}.tar.xz` (runtime libraries)

Other components produce a single tarball. Consult the download function in the relevant `.bzl` file to see exactly which tarballs are expected.

### 3. Compute SHA256 hashes for the new tarballs

Download each new tarball and compute its hash:

```bash
# Download to a temporary directory
gh release download binaries \
  --pattern "<new-tarball-name>" \
  --dir /tmp/release-artifacts

# Compute the SHA256 hash
sha256sum /tmp/release-artifacts/<new-tarball-name>
```

Repeat for every tarball that needs updating (e.g., both bins and libs for GCC).

### 4. Update `RELEASE_TO_DATE`

In the appropriate `.bzl` file, change the date value for the affected release name.

**Example** (in `gcc.bzl`):
```python
# Before
RELEASE_TO_DATE = {
    "x86_64-linux-x86_64-linux-gnu-gcc-15.2.0": "20260218",
}

# After
RELEASE_TO_DATE = {
    "x86_64-linux-x86_64-linux-gnu-gcc-15.2.0": "20260222",
}
```

### 5. Update `TARBALL_TO_SHA256`

Replace the old tarball entries with the new tarball names and their SHA256 hashes.

**Example** (in `gcc.bzl`):
```python
# Before
TARBALL_TO_SHA256 = {
    "x86_64-linux-x86_64-linux-gnu-gcc-15.2.0-20260218.tar.xz": "c8b6430d...",
    "x86_64-linux-gnu-gcc-lib-15.2.0-20260218.tar.xz": "12e61d6d...",
}

# After
TARBALL_TO_SHA256 = {
    "x86_64-linux-x86_64-linux-gnu-gcc-15.2.0-20260222.tar.xz": "<new-sha256>",
    "x86_64-linux-gnu-gcc-lib-15.2.0-20260222.tar.xz": "<new-sha256>",
}
```

### 6. Verify the build

Each example is its own Bazel module, so you must build each one individually. The `repo_env` flag format is `{toolchain_name}_{var_name}`, where the toolchain name comes from the `cc_toolchains.declare(name = ...)` tag in each example's `MODULE.bazel`. The examples all use `name = "my_toolchain"`, so the flags are `my_toolchain_target`, `my_toolchain_libc_version`, etc.

```bash
for example in examples/*/; do
  (cd "$example" && bazel build \
    --repo_env=my_toolchain_target=<target> \
    --repo_env=my_toolchain_libc_version=<libc_version> \
    --repo_env=my_toolchain_compiler_version=<compiler_version> \
    //...)
done
```

For example, after updating `x86_64-linux-gnu` with GCC 15.2.0 and glibc 2.28:

```bash
for example in examples/*/; do
  (cd "$example" && bazel build \
    --repo_env=my_toolchain_target=x86_64-linux-gnu \
    --repo_env=my_toolchain_libc_version=2.28 \
    --repo_env=my_toolchain_compiler_version=15.2.0 \
    //...)
done
```

Note: The `repo_env` flags override the hard-coded defaults in [private/config.bzl](../../private/config.bzl). If the updated component matches the current defaults, the flags are technically redundant but still recommended to be explicit about what you're testing.

## Important: Never Delete Old Artifacts

Old dated tarballs in the `binaries` release **must be preserved**. Previous versions of the module reference the old dates and hashes, and users who haven't updated must continue to be able to download them. This is the reason toolchain binaries are dated — each module version pins to a specific dated build, and only users who update the module get the new tarballs.

## Checklist

- [ ] Identified the correct download file for the rebuilt component
- [ ] Found the new dated artifacts in the `binaries` GitHub release
- [ ] Computed SHA256 hashes for all new tarballs
- [ ] Updated `RELEASE_TO_DATE` with the new date
- [ ] Updated `TARBALL_TO_SHA256` with the new tarball names and hashes
- [ ] `bazel build //...` succeeds in each example directory with `repo_env` flags targeting the updated toolchain

## Related Files

- [private/downloads/constants.bzl](../../private/downloads/constants.bzl): Base URL for the `binaries` release
- [private/downloads/all.bzl](../../private/downloads/all.bzl): Orchestrates all downloads
