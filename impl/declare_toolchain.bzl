load("@rules_cc//cc/toolchains:args.bzl", "cc_args")
load("//impl:config.bzl", "get_config_from_env_vars")
load("@rules_cc//cc/toolchains:toolchain.bzl", "cc_toolchain")

def _declare_toolchain(name, visibility, sysroot, all_tools):
    """Declares a CC toolchain with the specified configuration.
    
    Args:
        name: The name of the toolchain
        visibility: Visibility of the toolchain
        sysroot: Path to the sysroot
        all_tools: Map of all tools for the toolchain
    """
    native.toolchain(
        name = name,
        exec_compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:x86_64",
        ],
        target_compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:x86_64",
        ],
        toolchain = ":{}_cc_toolchain".format(name),
        toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
        visibility = visibility,
    )

    cc_toolchain(
        name = "{}_cc_toolchain".format(name),
        args = [
            ":{}-no-canonical-prefixes".format(name),
            ":{}-sysroot-arg".format(name),
        ],
        enabled_features = ["@rules_cc//cc/toolchains/args:experimental_replace_legacy_action_config_features"],
        known_features = ["@rules_cc//cc/toolchains/args:experimental_replace_legacy_action_config_features"],
        tool_map = all_tools,
        visibility = visibility,
    )

    # Bazel does not like absolute paths.
    # Clang will use absolute paths when reporting the include path for its headers causing bazel to error out.
    # This changes clang to prefer relative paths.
    # Symptom:
    # ERROR: C:/users/mark/desktop/new_toolchain/BUILD:1:10: Compiling main.c failed: absolute path inclusion(s) found in rule '//:main':
    # the source file 'main.c' includes the following non-builtin files with absolute paths (if these are builtin files, make sure these paths are in your toolchain):
    #   'C:/Users/mark/_bazel_mark/w77p7fta/external/+_repo_rules+llvm_toolchain/toolchain/lib/clang/19/include/vadefs.h'
    cc_args(
        name = "{}-no-canonical-prefixes".format(name),
        actions = [
            "@rules_cc//cc/toolchains/actions:c_compile",
            "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
            "@rules_cc//cc/toolchains/actions:link_actions",
        ],
        args = [
            "-no-canonical-prefixes",
            "-fno-canonical-system-headers", # gcc only?
        ],
        visibility = visibility,
    )

    cc_args(
        name = "{}-sysroot-arg".format(name),
        actions = [
            "@rules_cc//cc/toolchains/actions:c_compile",
            "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
            "@rules_cc//cc/toolchains/actions:link_actions",
        ],
        args = ["--sysroot={sysroot}"],
        format = {
            "sysroot": sysroot,
        },
        visibility = visibility,
    )

declare_toolchain = macro(
    attrs = {
        # configurable = False is required because macros wrap configurable attrs in
        # a select(...) which cant be used when inlining the labels and strings in
        # the toolchain declarations.
        "sysroot": attr.label(mandatory = True, configurable = False),
        "all_tools": attr.label(mandatory = True, configurable = False),
    },
    implementation = _declare_toolchain,
)

def _eager_declare_toolchain_impl(rctx):
    """Eagerly declare the toolchain(...) to determine which registered toolchain is valid for the current platform."""
    config = get_config_from_env_vars(rctx)

    rctx.file(
        "BUILD",
        """
load("@toolchains_cc//impl:declare_toolchain.bzl", "declare_toolchain")
declare_toolchain(
    name = "{original_name}",
    sysroot = "@@{bins_repo_name}//:{original_name}_bins.sysroot",
    all_tools = "@@{bins_repo_name}//:{original_name}_bins.all_tools",
    visibility = ["//visibility:public"],
)
""".format(
            original_name = rctx.original_name,
            target_triple = config["triple"],
            bins_repo_name = rctx.name + "_bins",
        ),
    )

eager_declare_toolchain = repository_rule(
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
