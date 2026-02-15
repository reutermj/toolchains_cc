# Native vs Cross Install Layout

## Problem

GCC's autoconf build system uses the relationship between `--build` and `--target` to decide its install layout. 
When the triples match, GCC treats the build as native and installs target artifacts (libstdc++, libgcc_s, headers) directly into `<prefix>/lib64/`, `<prefix>/include/`. 
When they differ, GCC installs them under `<prefix>/<target-triple>/`.

This means identical compiler configurations produce structurally different install trees depending on whether the build machine happens to match the target.
This distinction is irrelevant for the toolchains we precompile to be used with this Bazel module. 
These toolchains are distributed as archives and deployed by Bazel onto arbitrary machines with explicit `--sysroot` flags; 
the original build machine's identity doesn't matter. 
Without intervention, this autoconf heuristic forces artificial complexity into this Bazel module's toolchain configuration.

## Symptoms

This was discovered when adding musl support. 
The glibc toolchain (`--target=x86_64-linux-gnu`) produced a flat native layout, while the musl toolchain (`--target=x86_64-linux-musl`) produced a target-prefixed cross layout. 
Both were built on the same x86_64-linux-gnu machine. 
The glibc target matched the build machine's triple, triggering the native heuristic; 
the musl target didn't, so GCC treated it as a cross build.

Configuring GCC with matching `--build` and `--target` triples:

```bash
configure --build=x86_64-linux-gnu --target=x86_64-linux-gnu --prefix=/tmp/gcc-artifacts ...
```

Produces a native install layout:

```
/tmp/gcc-artifacts/
├── bin/                                 # Toolchain executables
│   ├── x86_64-linux-gnu-gcc
│   ├── ...
├── include/
├── lib/gcc/x86_64-linux-gnu/15.2.0/     # libgcc, compiler runtime libraries
├── lib64/                               # libstdc++, target libraries
├── libexec/gcc/x86_64-linux-gnu/15.2.0/ # GCC internal tooling (cc1, cc1plus, collect2, lto-wrapper)
└── share/
```

Configuring GCC with differing `--build` and `--target` triples:

```bash
configure --build=x86_64-bootstrap-linux-gnu --target=x86_64-linux-gnu --prefix=/tmp/gcc-artifacts ...
```

Produces a cross install layout:

```
/tmp/gcc-artifacts/
├── bin/                                 # Toolchain executables
│   ├── x86_64-linux-gnu-gcc
│   ├── ...
├── include/
├── lib/gcc/x86_64-linux-gnu/15.2.0/     # libgcc, compiler runtime libraries
├── libexec/gcc/x86_64-linux-gnu/15.2.0/ # GCC internal tooling (cc1, cc1plus, collect2, lto-wrapper)
├── share/
└── x86_64-linux-gnu/
    ├── include/
    ├── lib/
    └── lib64/                           # libstdc++, target libraries
```

In the native layout, target libraries like libstdc++ are placed directly in `lib64/` at the prefix root. 
In the cross layout, they are isolated under the `x86_64-linux-gnu/` subdirectory.
The cross layout is the desired structure for all toolchains regardless of target.

## Solution

We force the cross layout by changing the vendor field in the build triple. 
GCC's autoconf scripts directly compares `--build` and `--target` as strings, and
even a minor difference is enough to trigger the cross install layout.

The vendor field (the second component of a target triple: `cpu-vendor-os-abi`) is the natural place to introduce this difference. 
Unlike cpu, os, or abi, the vendor field is largely cosmetic.
A synthetic vendor like `bootstrap` is enough to force cross-compilation without affecting the compiler's output.

The bootstrap GCC (C only, `--with-newlib`) targets the synthetic vendor:

```bash
configure --build=x86_64-linux-gnu --target=x86_64-bootstrap-linux-gnu ...
```

The full GCC then builds from the bootstrap triple and targets the real triple:

```bash
configure --build=x86_64-bootstrap-linux-gnu --target=x86_64-linux-gnu ...
```

This guarantees `--build` never equals `--target` for any toolchain we produce,
regardless of the target architecture.

### Binutils

Building with `--build=x86_64-bootstrap-linux-gnu` requires binutils built for that triple
(GCC's build system expects to find `x86_64-bootstrap-linux-gnu-as`, `x86_64-bootstrap-linux-gnu-ld`, etc.).
We build a dedicated binutils tarball targeting the bootstrap vendor to provide these.
Other projects like crosstool-ng handle this via symlinks, but that adds fragile indirection.
Building a redundant binutils tarball is simpler and more explicit.
