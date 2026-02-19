# Remove Convenience Toolchain

## Problem

The convenience toolchain pattern doesn't work well for downstream modules.
This document details what the convenience toolchain is, why it's problematic,
what needs to change, and how to migrate all projects to use the extension API
directly.

## Background: How the Convenience Toolchain Works Today

The convenience toolchain is a set of interrelated pieces that let downstream
users register toolchains_cc with a single `register_toolchains("@toolchains_cc")`
call, without needing to interact with the module extension directly.

### The pieces

**1. `MODULE.bazel` declares a default toolchain (lines 22-34)**

```starlark
cc_toolchains = use_extension("@toolchains_cc//:extensions.bzl", "cc_toolchains")
cc_toolchains.declare(name = "toolchains_cc_default_toolchain")
use_repo(cc_toolchains, "toolchains_cc_default_toolchain")

register_toolchains(
    "@toolchains_cc",
    dev_dependency = True,
)
```

This declares a toolchain named `toolchains_cc_default_toolchain` inside
toolchains_cc's own MODULE.bazel. Even though `register_toolchains` is marked
`dev_dependency = True`, the `use_extension` and `cc_toolchains.declare()` calls
are **not** dev dependencies -- they execute for all consumers.

**2. `BUILD.bazel` creates an alias at the repo root**

```starlark
alias(
    name = "toolchains_cc",
    actual = "@toolchains_cc_default_toolchain",
)
```

This alias allows users to write `register_toolchains("@toolchains_cc")` instead
of `register_toolchains("@toolchains_cc_default_toolchain")`.

**3. `extensions.bzl` special-cases the default toolchain name**

```starlark
if declared_toolchain.name == "toolchains_cc_default_toolchain":
    toolchain_name = "toolchains_cc"
```

This makes the environment variable prefix `toolchains_cc_` instead of the
unwieldy `toolchains_cc_default_toolchain_`.

**4. Every example uses the convenience pattern**

All 12 examples use:
```starlark
bazel_dep(name = "toolchains_cc", version = "2025.9.18")
register_toolchains("@toolchains_cc")
```

None of them use the extension API directly.

## Why the Convenience Toolchain is Problematic for Downstream Modules

When a downstream module depends on `toolchains_cc`, the non-dev-dependency
`cc_toolchains.declare(name = "toolchains_cc_default_toolchain")` in
toolchains_cc's MODULE.bazel still executes. This means:

1. The `eager_declare_toolchain` repo rule runs for every consumer, creating the
   `@toolchains_cc_default_toolchain` repository, even if the consumer doesn't
   use it or declares their own toolchain with different settings.

2. The env var configuration of the eagerly-created default toolchain can
   interfere with or confuse the consumer's own toolchain configuration.

3. Consumers who want to use the extension API directly end up with both their
   own toolchain declaration AND the default one from toolchains_cc's MODULE.bazel.

4. The alias in BUILD.bazel and the special-casing in extensions.bzl add
   indirection that makes the system harder to understand and debug.

## What Needs to Change

### Files to Modify

#### 1. `MODULE.bazel` -- Remove convenience toolchain, keep dev-only toolchain

**Current** (lines 22-34):
```starlark
# ===========================
# || Convenience Toolchain ||
# ===========================
# For most use cases, this convenience toolchain is expected to be the only needed declaration.
# While the convenience toolchain is declared by default, it's left up to the user to register it.
cc_toolchains = use_extension("@toolchains_cc//:extensions.bzl", "cc_toolchains")
cc_toolchains.declare(name = "toolchains_cc_default_toolchain")
use_repo(cc_toolchains, "toolchains_cc_default_toolchain")

register_toolchains(
    "@toolchains_cc",
    dev_dependency = True,
)
```

**New**:
```starlark
# =====================
# || Dev Toolchains ||
# =====================
# Toolchain for testing toolchains_cc itself. Not visible to downstream modules.
cc_toolchains = use_extension("@toolchains_cc//:extensions.bzl", "cc_toolchains", dev_dependency = True)
cc_toolchains.declare(name = "toolchains_cc_dev")
use_repo(cc_toolchains, "toolchains_cc_dev")

register_toolchains(
    "@toolchains_cc_dev",
    dev_dependency = True,
)
```

Key changes:
- The entire `use_extension` call is now `dev_dependency = True`, so it won't
  execute for downstream modules at all.
- The toolchain is renamed from `toolchains_cc_default_toolchain` to
  `toolchains_cc_dev` to clearly signal its purpose.
- `register_toolchains` points directly to `@toolchains_cc_dev` (no alias needed).
- Env var prefix becomes `toolchains_cc_dev_` for this project's own testing.
  Alternatively, the special-case in extensions.bzl could be updated, but it's
  cleaner to just remove it entirely (see below).

#### 2. `BUILD.bazel` -- Remove the alias

**Current**:
```starlark
alias(
    name = "toolchains_cc",
    actual = "@toolchains_cc_default_toolchain",
)
```

**New**: Empty file or remove file entirely.

The alias only exists to support `register_toolchains("@toolchains_cc")`. With
the convenience toolchain gone, this alias has no purpose.

#### 3. `extensions.bzl` -- Remove the special-case naming

**Current** (lines 18-22):
```starlark
            # this special case is needed to make the default toolchain env vars start with
            # `toolchains_cc_` rather than `toolchains_cc_default_toolchain_`.
            toolchain_name = declared_toolchain.name
            if declared_toolchain.name == "toolchains_cc_default_toolchain":
                toolchain_name = "toolchains_cc"
```

**New**:
```starlark
            toolchain_name = declared_toolchain.name
```

The special-case only existed to support the convenience toolchain's naming
scheme. With the convenience toolchain removed, every toolchain just uses its
declared name as the env var prefix.

#### 4. `README.md` -- Update usage instructions

**Current**:
```markdown
Add to your `MODULE.bazel`

bazel_dep(name="toolchains_cc", version="2025.9.17")
register_toolchains(
    "@toolchains_cc",
    dev_dependency = True,
)
```

**New**:
```markdown
Add to your `MODULE.bazel`

bazel_dep(name = "toolchains_cc", version = "<next-version>")

cc_toolchains = use_extension("@toolchains_cc//:extensions.bzl", "cc_toolchains")
cc_toolchains.declare(name = "my_toolchain")
use_repo(cc_toolchains, "my_toolchain")

register_toolchains("@my_toolchain")
```

The user can name their toolchain whatever they want. Environment variables
will use the name as the prefix (e.g., `--repo_env=my_toolchain_target=...`).

#### 5. All 12 examples -- Update to use the extension API directly

Each example currently has:
```starlark
bazel_dep(name = "toolchains_cc", version = "2025.9.18")
local_path_override(module_name = "toolchains_cc", path = "../..")
register_toolchains("@toolchains_cc")
```

Each should become:
```starlark
bazel_dep(name = "toolchains_cc", version = "2025.9.18")
local_path_override(module_name = "toolchains_cc", path = "../..")

cc_toolchains = use_extension("@toolchains_cc//:extensions.bzl", "cc_toolchains")
cc_toolchains.declare(name = "my_toolchain")
use_repo(cc_toolchains, "my_toolchain")

register_toolchains("@my_toolchain")
```

The examples serve as documentation for users, so they should demonstrate the
correct usage pattern.

**Affected examples** (all 12):
- `examples/boost/MODULE.bazel`
- `examples/curl/MODULE.bazel`
- `examples/fmt/MODULE.bazel`
- `examples/googletest/MODULE.bazel`
- `examples/grpc/MODULE.bazel`
- `examples/libarchive/MODULE.bazel`
- `examples/libuv/MODULE.bazel`
- `examples/nlohmann_json/MODULE.bazel`
- `examples/protobuf/MODULE.bazel`
- `examples/sqlite/MODULE.bazel`
- `examples/zlib/MODULE.bazel`
- `examples/zstd/MODULE.bazel`

### Files That Need No Changes

- `private/config.bzl` -- No changes needed. Config already uses
  `rctx.attr.toolchain_name` for the env var prefix, which works with any name.
- `private/eager_declare_toolchain.bzl` -- No changes needed.
- `private/lazy_download_bins.bzl` -- No changes needed.
- `private/declare_toolchain.bzl` -- No changes needed.
- `private/declare_tools.bzl` -- No changes needed.
- `private/download_bins.bzl` -- No changes needed.
- `tests/hello_world/BUILD.bazel` -- No changes needed (tests use whatever
  toolchain is registered, which will now be `@toolchains_cc_dev`).

## Summary of Changes

| File | Change |
|------|--------|
| `MODULE.bazel` | Replace convenience toolchain with dev-only toolchain |
| `BUILD.bazel` | Remove alias (file becomes empty or deleted) |
| `extensions.bzl` | Remove `toolchains_cc_default_toolchain` special-case |
| `README.md` | Update usage instructions to show extension API |
| `examples/*/MODULE.bazel` (x12) | Switch from `register_toolchains("@toolchains_cc")` to extension API |

**Total files modified**: 16

## Migration Guide for Downstream Users

Users currently doing:
```starlark
bazel_dep(name = "toolchains_cc", version = "2025.9.18")
register_toolchains("@toolchains_cc")
```

Must migrate to:
```starlark
bazel_dep(name = "toolchains_cc", version = "<next-version>")

cc_toolchains = use_extension("@toolchains_cc//:extensions.bzl", "cc_toolchains")
cc_toolchains.declare(name = "my_toolchain")
use_repo(cc_toolchains, "my_toolchain")

register_toolchains("@my_toolchain")
```

And update any `--repo_env` flags to use the new toolchain name prefix:
- Old: `--repo_env=toolchains_cc_target=x86_64-linux-gnu`
- New: `--repo_env=my_toolchain_target=x86_64-linux-gnu`

This is a **breaking change** for downstream users.

## Open Questions

1. **Toolchain name for examples**: Should all examples use a consistent name
   like `my_toolchain`, or should each example use its own name (e.g.,
   `fmt_example_toolchain`)? Using `my_toolchain` is simpler and more
   copy-paste-friendly for users reading the examples.

2. **Dev toolchain env var prefix**: With the dev toolchain renamed to
   `toolchains_cc_dev`, the env var prefix becomes `toolchains_cc_dev_`
   (e.g., `--repo_env=toolchains_cc_dev_target=...`). This is slightly longer
   but clear. Alternatively, the CLAUDE.md build instructions would need
   updating to reflect the new prefix.

3. **CLAUDE.md build instructions**: The build section currently shows
   `--repo_env=toolchains_cc_target=...`. This will need to change to
   `--repo_env=toolchains_cc_dev_target=...` after the migration.
