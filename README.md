# C/C++ Toolchains for Bazel

### What is toolchains_cc?

toolchains_cc is an easy to use C/C++ toolchain module for Bazel that provides hermetic toolchains and sysroots.

### How do I use toolchains_cc in my Bazel project?

Add to your `MODULE.bazel`

```starlark
bazel_dep(name = "toolchains_cc", version = "2025.9.18")

cc_toolchains = use_extension("@toolchains_cc//:extensions.bzl", "cc_toolchains")
cc_toolchains.declare(name = "my_toolchain")
use_repo(cc_toolchains, "my_toolchain")

register_toolchains("@my_toolchain")
```

Configure using `--repo_env` flags (optional, defaults to gcc 15.2.0, glibc 2.28, x86_64-linux-gnu):

```bash
bazel build \
  --repo_env=my_toolchain_target=x86_64-linux-gnu \
  --repo_env=my_toolchain_libc_version=2.39 \
  --repo_env=my_toolchain_compiler_version=15.2.0 \
  //...
```

Note: toolchains_cc does not support the legacy `WORKSPACE` system
