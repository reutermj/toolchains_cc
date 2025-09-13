load("@bazel_skylib//rules/directory:directory.bzl", "directory")
load("@bazel_skylib//rules/directory:subdirectory.bzl", "subdirectory")
load("@rules_cc//cc/toolchains:tool.bzl", "cc_tool")
load("@rules_cc//cc/toolchains:tool_map.bzl", "cc_tool_map")
load("//impl:config.bzl", "get_config_from_env_vars", "repro_dump")

def _declare_tools(name, visibility, all_files):
    native.filegroup(
        name = "{}.all_files".format(name),
        srcs = all_files,
        visibility = visibility,
    )

    directory(
        name = "{}.root".format(name),
        srcs = [":{}.all_files".format(name)],
        visibility = visibility,
    )

    subdirectory(
        name = "{}.sysroot".format(name),
        parent = ":{}.root".format(name),
        path = "x86_64-linux-gnu/sysroot",
        visibility = visibility,
    )

    cc_tool_map(
        name = "{}.all_tools".format(name),
        tools = {
            "@rules_cc//cc/toolchains/actions:ar_actions": ":{}.ar_actions".format(name),
            "@rules_cc//cc/toolchains/actions:assembly_actions": ":{}.assembly_actions".format(name),
            "@rules_cc//cc/toolchains/actions:c_compile": ":{}.c_compile".format(name),
            "@rules_cc//cc/toolchains/actions:cpp_compile_actions": ":{}.cpp_compile_actions".format(name),
            "@rules_cc//cc/toolchains/actions:link_actions": ":{}.link_actions".format(name),
            "@rules_cc//cc/toolchains/actions:objcopy_embed_data": ":{}.objcopy_embed_data".format(name),
            "@rules_cc//cc/toolchains/actions:strip": ":{}.strip".format(name),
        },
        visibility = visibility,
    )

    cc_tool(
        name = "{}.ar_actions".format(name),
        src = ":bin/x86_64-linux-gnu-ar",
        data = [":{}.all_files".format(name)],
        visibility = visibility,
    )

    cc_tool(
        name = "{}.assembly_actions".format(name),
        src = ":bin/x86_64-linux-gnu-gcc",
        data = [":{}.all_files".format(name)],
        visibility = visibility,
    )

    cc_tool(
        name = "{}.c_compile".format(name),
        src = ":bin/x86_64-linux-gnu-gcc",
        data = [":{}.all_files".format(name)],
        visibility = visibility,
    )

    cc_tool(
        name = "{}.cpp_compile_actions".format(name),
        src = ":bin/x86_64-linux-gnu-g++",
        data = [":{}.all_files".format(name)],
        visibility = visibility,
    )

    cc_tool(
        name = "{}.link_actions".format(name),
        src = ":bin/x86_64-linux-gnu-g++",
        data = [":{}.all_files".format(name)],
        visibility = visibility,
    )

    cc_tool(
        name = "{}.objcopy_embed_data".format(name),
        src = ":bin/x86_64-linux-gnu-objcopy",
        data = [":{}.all_files".format(name)],
        visibility = visibility,
    )

    cc_tool(
        name = "{}.strip".format(name),
        src = ":bin/x86_64-linux-gnu-strip",
        data = [":{}.all_files".format(name)],
        visibility = visibility,
    )

declare_tools = macro(
    attrs = {
        "all_files": attr.label_list(mandatory = True, configurable = False),
    },
    implementation = _declare_tools,
)

def _lazy_download_bins_impl(rctx):
    """Lazily downloads only the toolchain binaries for the configured platform."""
    config = get_config_from_env_vars(rctx)
    repro_dump(rctx, config)

    if config["os"] == "windows" and not config["accept_winsdk_license"]:
        fail(
            """
Please view the Microsoft Visual Studio License terms: https://go.microsoft.com/fwlink/?LinkId=2086102.
Accept the license by setting `--repo_env={}_accept_winsdk_license=True` in your toolchain declaration.
""".format(rctx.attr.toolchain_name)
        )

    # TODO: figure out how to package the toolchain and sysroot separately
    #       currently the issue is that libstdc++ headers are outside the sysroot directory for who knows what reason....
    rctx.download_and_extract(
        url = "https://github.com/reutermj/toolchains_cc/releases/download/binaries/toolchain.tar.xz",
    )
    rctx.download_and_extract(
        url = "https://github.com/reutermj/toolchains_cc/releases/download/binaries/sysroot.tar.xz",
    )

    rctx.file(
        "BUILD",
        """
load("@toolchains_cc//impl:declare_tools.bzl", "declare_tools")
declare_tools(
    name = "{original_name}",
    all_files = glob(["**"]),
    visibility = ["//visibility:public"],
)
""".format(
            original_name = rctx.original_name,
        ),
    )

lazy_download_bins = repository_rule(
    implementation = _lazy_download_bins_impl,
    attrs = {
        "toolchain_name": attr.string(
            mandatory = True,
            doc = "The name of the toolchain, used for registration.",
        ),
        "_build_tpl": attr.label(
            default = "@toolchains_cc//:bins.BUILD.tpl",
        ),
    },
)
