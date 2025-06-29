"""Defines the repo rules and module extension for managing C++ toolchains across different platforms."""

load("//impl:alpine.bzl", "extract_alpine")
load("//impl:config.bzl", "get_config_from_env_vars", "repro_dump")
load("//impl:ubuntu.bzl", "extract_ubuntu")

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

def _eager_declare_toolchain_impl(rctx):
    """Eagerly declare the toolchain(...) to determine which registered toolchain is valid for the current platform."""
    config = get_config_from_env_vars(rctx)

    rctx.file(
        "BUILD",
        """
load("@toolchains_cc//impl:declare_toolchain.bzl", "declare_toolchain")
load("@rules_cc//cc/toolchains:toolchain.bzl", "cc_toolchain")
declare_toolchain(
    name = "{original_name}",
    cxx_std_lib = "{cxx_std_lib}",
    vendor = "{vendor}",
    target_triple = "{target_triple}",
    sysroot = "@@{bins_repo_name}//:{original_name}_bins.sysroot",
    all_tools = "@@{bins_repo_name}//:{original_name}_bins.all_tools",
    visibility = ["//visibility:public"],
)

# TODO: currently cant declare this in the macro because this rule creates
#       a target that doesnt following the naming rules of macros.
cc_toolchain(
    name = "{original_name}_cc_toolchain",
    args = [
        ":{original_name}-no-canonical-prefixes",
        ":{original_name}_target_triple",
        ":{original_name}-sysroot-arg",
        ":{original_name}_use_llvm_linker",
        ":{original_name}_cxx_std_lib",
    ],
    enabled_features = ["@rules_cc//cc/toolchains/args:experimental_replace_legacy_action_config_features"],
    known_features = ["@rules_cc//cc/toolchains/args:experimental_replace_legacy_action_config_features"],
    tool_map = "@@{bins_repo_name}//:{original_name}_bins.all_tools",
    visibility = ["//visibility:public"],
)
""".format(
            original_name = rctx.original_name,
            cxx_std_lib = config["cxx_std_lib"],
            vendor = config["vendor"],
            target_triple = config["triple"],
            bins_repo_name = rctx.name + "_bins",
        ),
    )

_lazy_download_bins = repository_rule(
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

_eager_declare_toolchain = repository_rule(
    implementation = _eager_declare_toolchain_impl,
    attrs = {
        "toolchain_name": attr.string(
            mandatory = True,
            doc = "The name of the toolchain, used for registration.",
        ),
        "_build_tpl": attr.label(
            default = "@toolchains_cc//:toolchain.BUILD.tpl",
        ),
    },
)

def _cxx_toolchains(module_ctx):
    for mod in module_ctx.modules:
        for declared_toolchain in mod.tags.declare:
            # TODO: move to env vars
            #             if declared_toolchain.vendor == "windows" and not declared_toolchain.accept_winsdk_license:
            #                 fail(
            #                     """
            # Please view the Microsoft Visual Studio License terms: https://go.microsoft.com/fwlink/?LinkId=2086102.
            # Accept the license by setting `accept_winsdk_license = True` in your toolchain declaration:
            # cc_toolchains.declare(
            #     name = "{}",
            #     vendor = "{}",
            #     accept_winsdk_license = True,
            # )
            # """.format(
            #                         declared_toolchain.name,
            #                         declared_toolchain.vendor,
            #                         declared_toolchain.cxx_std_lib,
            #                     ),
            #                 )

            # we need to use a module extension + two repository rules
            # to enable lazy downloading of the toolchain binaries
            # when registering many toolchains.
            # repository rules arent allowed to call other repository rules,
            # so we have to wrap the two repository rules in a module extension.
            # `_eager_declare_toolchain` declares the toolchain(...) which is eagerly evaluated
            # for every registered toolchain. This allows bazel to determime
            # which toolchain is valid for the current platform.
            # `_lazy_download_bins` only downloads the binaries when the toolchain
            # is actually used in a build.
            # more context: https://github.com/reutermj/toolchains_cc.bzl/issues/1

            # TODO: not super happy with this special case
            # it's needed to make the default toolchain env vars start with
            # `toolchains_cc_` rather than `toolchains_cc_default_toolchain_`.
            toolchain_name = declared_toolchain.name
            if declared_toolchain.name == "toolchains_cc_default_toolchain":
                toolchain_name = "toolchains_cc"

            _eager_declare_toolchain(
                name = declared_toolchain.name,
                toolchain_name = toolchain_name,
            )
            _lazy_download_bins(
                name = declared_toolchain.name + "_bins",
                toolchain_name = toolchain_name,
            )

cxx_toolchains = module_extension(
    implementation = _cxx_toolchains,
    tag_classes = {
        "declare": tag_class(
            attrs = {
                "name": attr.string(
                    mandatory = True,
                    doc = "The name of the toolchain, used for registration.",
                ),
            },
        ),
    },
)
