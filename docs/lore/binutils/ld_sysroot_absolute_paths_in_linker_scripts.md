# ld Fails to Resolve Absolute Paths in glibc Linker Scripts Under Bazel Sandbox

## Problem Summary

Linking a simple C++ program fails because `ld` cannot find libraries referenced by absolute path inside glibc's linker scripts. The sysroot is correctly configured, but `ld` tries to open `/lib64/libm.so.6` on the host filesystem instead of `<sysroot>/lib64/libm.so.6`.

## Symptoms

When building `//tests/hello_world:hello` with a cross-toolchain configured with `--sysroot`:

```
ld: cannot find /lib64/libm.so.6: No such file or directory
ld: cannot find /usr/lib64/libmvec_nonshared.a: No such file or directory
ld: cannot find /lib64/libmvec.so.1: No such file or directory
```

### Diagnostic Clues

Verbose linker output (`-v`) shows that `ld` finds `libm.so` inside the sysroot correctly:

```
attempt to open external/+cc_toolchains+toolchains_cc_default_toolchain_bins/usr/lib/../lib64/libm.so succeeded
opened script file external/+cc_toolchains+toolchains_cc_default_toolchain_bins/usr/lib/../lib64/libm.so
```

But when it parses the linker script inside that file and encounters the absolute paths from its `GROUP` directive, it tries them literally on the host:

```
attempt to open /lib64/libm.so.6 failed
attempt to open /usr/lib64/libmvec_nonshared.a failed
attempt to open /lib64/libmvec.so.1 failed
```

## Background: glibc Libraries Are Linker Scripts

On glibc-based systems, several "shared libraries" are not ELF binaries — they are short **linker scripts** (ld scripts). glibc installs these because the actual implementation is split across multiple objects. For example, `libm.so` is typically a text file:

```
/* GNU ld script */
GROUP ( /lib64/libm.so.6 AS_NEEDED ( /lib64/libmvec_nonshared.a /lib64/libmvec.so.1 ) )
```

This tells `ld` to link against the real shared object (`libm.so.6`) plus additional objects. Other common glibc ld scripts include `libc.so` and `libpthread.so`.

The paths inside these scripts are **absolute**, reflecting where glibc was installed on the original system. This works for native compilation because `/lib64/libm.so.6` exists on the host. For cross-compilation or sandboxed builds with `--sysroot`, the linker must prepend the sysroot to those absolute paths.

## Root Cause

When `ld` is invoked with `--sysroot=<path>`, it uses `is_sysrooted_pathname()` to decide whether absolute paths from linker scripts should be resolved relative to the sysroot. This function **canonicalizes both paths** via `lrealpath()` (which calls `realpath()`) and checks whether the script's resolved path starts with the sysroot's resolved path.

This breaks in Bazel's sandbox. Bazel constructs sandbox directories where the directory structure is real, but leaf files are **symlinks** pointing into the external repository cache. After `realpath()`, the script's canonical location resolves to somewhere in the cache (e.g., `/home/user/.cache/bazel/...`), which does not start with the sysroot prefix. So `is_sysrooted_pathname()` returns false, and `ld` treats the absolute paths literally instead of prepending the sysroot.

### Why This Specifically Affects Bazel

In a typical cross-compilation setup, the sysroot is a real directory tree and `realpath()` preserves the prefix relationship. Bazel's sandboxing breaks this assumption by creating a directory tree of symlinks, so `realpath()` resolves out of the sandbox entirely.

## Upstream Bug History

This is a known class of bug with a long upstream history:

- **Gentoo [#275666](https://bugs.gentoo.org/275666)** (2009): Cross-compilation with sysroot failed because `ld` searched the host filesystem before the sysroot when linker scripts contained absolute paths. Fixed in binutils 2.19.51.0.12.

- **Sourceware [#10340](https://sourceware.org/bugzilla/show_bug.cgi?id=10340)** (2009): Same core issue reported upstream. Alan Modra committed a fix in 2012 refactoring `ldfile.c`, `ldlang.c`, and `ldlex.l` to better track sysroot prefixes during linker script processing.

The upstream fix improved the situation but still relies on `is_sysrooted_pathname()` with `realpath()`-based canonicalization, so it continues to fail when symlinks break the prefix check.

## The Fix

We apply a patch to binutils: `.github/workflows/build_binutils/patches/0001-ld-always-try-sysroot-prefix-for-absolute-paths.patch`

The patch changes `ldfile_open_file_search()` in `ld/ldfile.c`:

**Before (upstream):** If `is_sysrooted_pathname()` says the file is within the sysroot AND the path is absolute, prepend the sysroot. Otherwise, try the path as-is. These two branches are mutually exclusive (`if`/`else if`).

**After (patched):** For any absolute path when a sysroot is configured, **always try** prepending the sysroot first regardless of what `is_sysrooted_pathname()` returns. If the sysroot-prefixed path exists, use it. If not, fall back to the original absolute path. The `else if` becomes a plain `if`, making the two attempts independent.

This is a conservative change: it only adds a best-effort sysroot lookup before the existing fallback path. When the sysroot-prefixed file doesn't exist, behavior is unchanged.
