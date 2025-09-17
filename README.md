# C/C++ Toolchains for Bazel

### What is toolchains_cc?

toolchains_cc is an easy to use C/C++ toolchain module for Bazel that provides hermetic toolchains and sysroots.

### How do I use toolchains_cc in my Bazel project?

Add to your `MODULE.bazel`

```
bazel_dep(name="toolchains_cc", version="2025.9.17")
register_toolchains(
    "@toolchains_cc",
    dev_dependency = True,
)
```

Note: toolchains_cc does not support the legacy `WORKSPACE` system
