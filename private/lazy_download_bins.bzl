"""Repo rule for lazily downloading the C/C++ toolchain binaries when first used."""

load("//private/downloads:all.bzl", "download_all")
load(":config.bzl", "get_config_from_env_vars", "repro_dump")

def _lazy_download_bins(rctx):
    config = get_config_from_env_vars(rctx)
    repro_dump(rctx, config)
    download_all(rctx, config)

    rctx.file(
        "BUILD",
        """
load("@toolchains_cc//private:declare_tools.bzl", "declare_tools")

declare_tools(
    name = "{original_name}",
    all_files = glob(["**"]),
    target_platform = "{target_platform}",
    compiler = "{compiler}",
    visibility = ["//visibility:public"],
)
""".lstrip().format(
            original_name = rctx.original_name,
            target_platform = config["target"],
            compiler = config["compiler"],
        ),
    )

lazy_download_bins = repository_rule(
    implementation = _lazy_download_bins,
    attrs = {
        "toolchain_name": attr.string(
            mandatory = True,
            doc = "The name of the toolchain, used for registration.",
        ),
    },
)
