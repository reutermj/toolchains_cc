"""Utility functions for handling toolchains_cc configurations."""

visibility("//private/...")

# Configuration priority (highest to lowest):
# 1. --repo_env flags (CLI / .bazelrc) — for CI matrix builds
# 2. MODULE.bazel tag attributes (via config_overrides) — for project defaults
# 3. Hard-coded defaults below — fallback
#
# --repo_env is essential for CI configuration matrices (e.g. testing gcc vs clang, glibc vs musl).
# Due to Bazel phases, bazel_skylib string_flag(...) is not an option for this.
# See: https://bazel.build/extending/repo#when_is_the_implementation_function_executed

def _get_config(rctx, var_name, default, config_overrides):
    # --repo_env takes highest priority
    var = "{}_{}".format(rctx.attr.toolchain_name, var_name)
    value = rctx.getenv(var)
    if value != None:
        return value

    # MODULE.bazel tag attributes take medium priority
    if var_name in config_overrides:
        return config_overrides[var_name]

    return default

def _validate_config(config):
    for key, supported in SUPPORTED_VERSIONS.items():
        value = config[key]
        if value not in supported:
            fail("Unsupported {key}={value}. Supported values: {supported}".format(
                key = key,
                value = value,
                supported = ", ".join(sorted(supported.keys())),
            ))

def get_config(rctx):
    """Populates the configuration dictionary from MODULE.bazel tag attributes and environment variables.

    Args:
      rctx: The repository context.

    Returns:
        The configuration dictionary.
    """
    config_overrides = rctx.attr.config_overrides
    config = {
        "target": _get_config(rctx, "target", "x86_64-linux-gnu", config_overrides),
        "libc_version": _get_config(rctx, "libc_version", "2.28", config_overrides),
        "binutils_version": _get_config(rctx, "binutils_version", "2.45", config_overrides),
        "compiler": _get_config(rctx, "compiler", "gcc", config_overrides),
        "compiler_version": _get_config(rctx, "compiler_version", "15.2.0", config_overrides),
        "linux_headers_version": _get_config(rctx, "linux_headers_version", "6.18", config_overrides),
    }

    _validate_config(config)

    return config

def repro_dump(rctx, config):
    """Print configuration settings for reproducing the build.

    Args:
      rctx: The repository context.
      config: The configuration dictionary.
    """

    # buildifier: disable=print
    print("""
--------============[[  Begin toolchains_cc repro dump  ]]============--------
For reproducing this build, use the following configurations in your .bazelrc:
common --repo_env={name}_target={target}
common --repo_env={name}_compiler_version={compiler_version}
common --repo_env={name}_libc_version={libc_version}
--------============[[   End toolchains_cc repro dump   ]]============--------
""".format(
        name = rctx.attr.toolchain_name,
        target = config["target"],
        libc_version = config["libc_version"],
        compiler = config["compiler"],
        compiler_version = config["compiler_version"],
    ))

# Each component is validated independently since downloads are decoupled.
# To add a new supported version, add it here and in the corresponding
# private/downloads/*.bzl file (RELEASE_TO_DATE + TARBALL_TO_SHA256).
SUPPORTED_VERSIONS = {
    "target": {
        "x86_64-linux-gnu": True,
    },
    "libc_version": {
        "2.28": True,
    },
    "compiler": {
        "gcc": True,
    },
    "compiler_version": {
        "15.2.0": True,
    },
    "binutils_version": {
        "2.45": True,
    },
    "linux_headers_version": {
        "6.18": True,
    },
}
