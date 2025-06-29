load("@bazel_skylib//rules/directory:directory.bzl", "directory")
load("@bazel_skylib//rules/directory:subdirectory.bzl", "subdirectory")
load("@rules_cc//cc/toolchains:tool.bzl", "cc_tool")
load("@rules_cc//cc/toolchains:tool_map.bzl", "cc_tool_map")
load("//impl:alpine.bzl", "extract_alpine")
load("//impl:config.bzl", "get_config_from_env_vars", "repro_dump")
load("//impl:ubuntu.bzl", "extract_ubuntu")

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
        path = "sysroot",
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
        src = select({
            "@platforms//os:windows": ":toolchain/bin/llvm-ar.exe",
            "//conditions:default": ":toolchain/bin/llvm-ar",
        }),
        data = [":{}.all_files".format(name)],
        visibility = visibility,
    )

    cc_tool(
        name = "{}.assembly_actions".format(name),
        src = select({
            "@platforms//os:windows": ":toolchain/bin/clang++.exe",
            "//conditions:default": ":toolchain/bin/clang++",
        }),
        data = [":{}.all_files".format(name)],
        visibility = visibility,
    )

    cc_tool(
        name = "{}.c_compile".format(name),
        src = select({
            "@platforms//os:windows": ":toolchain/bin/clang.exe",
            "//conditions:default": ":toolchain/bin/clang",
        }),
        data = [":{}.all_files".format(name)],
        visibility = visibility,
    )

    cc_tool(
        name = "{}.cpp_compile_actions".format(name),
        src = select({
            "@platforms//os:windows": ":toolchain/bin/clang++.exe",
            "//conditions:default": ":toolchain/bin/clang++",
        }),
        data = [":{}.all_files".format(name)],
        visibility = visibility,
    )

    cc_tool(
        name = "{}.link_actions".format(name),
        src = select({
            "@platforms//os:windows": ":toolchain/bin/clang++.exe",
            "//conditions:default": ":toolchain/bin/clang++",
        }),
        data = [":{}.all_files".format(name)],
        visibility = visibility,
    )

    cc_tool(
        name = "{}.objcopy_embed_data".format(name),
        src = select({
            "@platforms//os:windows": ":toolchain/bin/llvm-objcopy.exe",
            "//conditions:default": ":toolchain/bin/llvm-objcopy",
        }),
        data = [":{}.all_files".format(name)],
        visibility = visibility,
    )

    cc_tool(
        name = "{}.strip".format(name),
        src = select({
            "@platforms//os:windows": ":toolchain/bin/llvm-strip.exe",
            "//conditions:default": ":toolchain/bin/llvm-strip",
        }),
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

    # TODO: not a huge fan of vendor == "unknown" but it's how ubuntu distrubtions are packaged
    if config["vendor"] == "unknown":
        extract_ubuntu(rctx, config)
    elif config["vendor"] == "alpine":
        extract_alpine(rctx, config)
    else:
        fail("(toolchains_cc.bzl bug) Unknown vendor: %s" % config["vendor"])

    rctx.download_and_extract(
        url = "https://github.com/reutermj/toolchains_cc.bzl/releases/download/binaries/llvm-19.1.7-linux-x86_64.tar.xz",
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
