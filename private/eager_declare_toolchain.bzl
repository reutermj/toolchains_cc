"""Repo rule for eagerly declaring the C/C++ toolchain for use with register_toolchain(...)."""

load(":config.bzl", "get_config_from_env_vars")

def _eager_declare_toolchain(rctx):
    config = get_config_from_env_vars(rctx)

    rctx.file(
        "BUILD",
        """
load("@toolchains_cc//private:declare_toolchain.bzl", "declare_toolchain")

declare_toolchain(
    name = "{original_name}",
    sysroot = "@@{bins_repo_name}//:{original_name}_bins_sysroot",
    all_tools = "@@{bins_repo_name}//:{original_name}_bins_all_tools",
    compiler = "{compiler}",
    visibility = ["//visibility:public"],
)
""".lstrip().format(
            original_name = rctx.original_name,
            bins_repo_name = rctx.name + "_bins",
            compiler = config["compiler"],
        ),
    )

eager_declare_toolchain = repository_rule(
    implementation = _eager_declare_toolchain,
    attrs = {
        "toolchain_name": attr.string(
            mandatory = True,
            doc = "The name of the toolchain, used for registration.",
        ),
    },
)
