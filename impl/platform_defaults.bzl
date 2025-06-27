"""Utilities for detecting features of the host platform."""

load(":config.bzl", "get_config_from_env_vars")

visibility(["//..."])

def _platform_defaults_impl(rctx):
    config = get_config_from_env_vars(rctx, "toolchains_cc")

    rctx.file("BUILD")
    rctx.file(
        "platform_constants.bzl",
        content = """VENDOR = "{}"
LIBC_VERSION = "{}"
CXX_STD_LIB = "{}"
TRIPLE = "{}"
""".format(
            config["vendor"],
            config["libc_version"],
            config["cxx_std_lib"],
            config["triple"],
        ),
    )

platform_defaults = repository_rule(
    implementation = _platform_defaults_impl,
)
