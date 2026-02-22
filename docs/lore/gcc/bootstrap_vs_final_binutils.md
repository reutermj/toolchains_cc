# GCC Requires Target-Matching Binutils

## Problem Summary

When building GCC with `--target=<triple>`, the build requires binutils whose tool prefix exactly matches that triple. GCC's build system looks for `<triple>-as`, `<triple>-ld`, etc. on `PATH`. If these don't exist, the build fails during `configure-target-libgcc` when the newly built `xgcc` tries to compile a test program for the target.

This applies to all GCC builds regardless of whether they are bootstrap or final:

- Building `--target=x86_64-linux-musl` requires `x86_64-linux-musl-ld`
- Building `--target=x86_64-bootstrap-linux-gnu` requires `x86_64-bootstrap-linux-gnu-ld`
- Building `--target=x86_64-linux-gnu` requires `x86_64-linux-gnu-ld`

## Symptoms

The build fails at `step-4.5_build_gcc` with:

```
configure: error: in `/tmp/gcc-build/<target>/libgcc':
configure: error: cannot compute suffix of object files: cannot compile
See `config.log' for more details
make[1]: *** [Makefile:13870: configure-target-libgcc] Error 1
```

This happens when GCC's newly built `xgcc` tries to compile a test program for the target. The configure script invokes `xgcc`, which in turn looks for an assembler and linker matching the `--target` triple. When those tools don't exist on `PATH`, the test compilation fails.

## Background

The `build_gcc` workflow produces two kinds of GCC:

1. **Bootstrap GCC** (`--target=x86_64-bootstrap-linux-{gnu,musl}`): Minimal C-only compiler used to build libc.
2. **Final GCC** (`--target=x86_64-linux-{gnu,musl}`): Full C/C++ compiler for end users.

Each requires a matching set of binutils. This is because GCC's `--target` flag determines the exact prefix it uses when searching for the assembler and linker. Having binutils for a *different* triple — even one that produces identical output — doesn't help. `x86_64-bootstrap-linux-musl-ld` and `x86_64-linux-musl-ld` are functionally identical binaries, but GCC only looks for the one matching its `--target`.

### What About `--build` and `--host` Binutils?

The full GCC build uses a synthetic `--build`/`--host` triple to force the cross install layout (see `docs/lore/gcc/native_vs_cross_install_layout.md`):

```bash
configure --build=x86_64-bootstrap-linux-gnu --host=x86_64-bootstrap-linux-gnu --target=x86_64-linux-musl ...
```

In theory, GCC's build system also looks for `--host`-prefixed tools (`x86_64-bootstrap-linux-gnu-as`, etc.) to compile the compiler itself. In practice, because the host is just the native build machine, GCC falls back to the system's native tools (`/usr/bin/as`, `/usr/bin/gcc`) when it can't find host-prefixed ones. So bootstrap binutils are not needed for full builds.

## The Fix

Install the binutils whose target prefix matches the GCC being built:

```bash
# step-3.2_install_binutils

# Bootstrap builds: GCC --target is x86_64-bootstrap-linux-{gnu,musl}
if [[ "${BOOTSTRAP}" == "true" ]]; then
    # provides x86_64-bootstrap-linux-musl-ld, etc.
    download_tarball "x86_64-linux-x86_64-bootstrap-linux-musl-binutils-2.45-" ...
fi

# Full builds: GCC --target is x86_64-linux-{gnu,musl}
if [[ "${BOOTSTRAP}" == "false" ]]; then
    # provides x86_64-linux-musl-ld, etc.
    download_tarball "x86_64-linux-x86_64-linux-musl-binutils-2.45-" ...
fi
```

The key insight is that the binutils triple must match `--target`, not `--build` or `--host`.
