load("@rules_cc//cc/toolchains:args.bzl", "cc_args")
# load("@rules_cc//cc/toolchains:toolchain.bzl", "cc_toolchain")

def _declare_toolchain(name, visibility, cxx_std_lib, vendor, sysroot, all_tools, target_triple):
    # buildifier: disable=unused-variable
    _unused = all_tools

    native.toolchain(
        name = name,
        exec_compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:x86_64",
        ],
        target_compatible_with = [
            "@platforms//os:linux",
            "@platforms//cpu:x86_64",
            "@toolchains_cc//c++:{}".format(cxx_std_lib),
            "@toolchains_cc//vendor:{}".format(vendor),
        ],
        toolchain = ":{}_cc_toolchain".format(name),
        toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
        visibility = visibility,
    )

    # TODO: currently cant use a macro for this because this rule creates
    #       a target named "_{}_cc_toolchain" which is not allowed in macros.
    # cc_toolchain(
    #     name = "{}_cc_toolchain".format(name),
    #     args = [
    #         ":{}-no-canonical-prefixes".format(name),
    #         ":{}_target_triple".format(name),
    #         ":{}-sysroot-arg".format(name),
    #         ":{}_use_llvm_linker".format(name),
    #         ":{}_cxx_std_lib".format(name),
    #     ],
    #     enabled_features = ["@rules_cc//cc/toolchains/args:experimental_replace_legacy_action_config_features"],
    #     known_features = ["@rules_cc//cc/toolchains/args:experimental_replace_legacy_action_config_features"],
    #     tool_map = all_tools,
    #     visibility = visibility,
    # )

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
        args = ["-no-canonical-prefixes"],
        visibility = visibility,
    )

    # by default, clang uses ld.
    # no sane person wants to use ld.
    # tell clang to use a good linker.
    cc_args(
        name = "{}_use_llvm_linker".format(name),
        actions = [
            "@rules_cc//cc/toolchains/actions:link_actions",
        ],
        args = ["-fuse-ld=lld"],
        visibility = visibility,
    )

    cc_args(
        name = "{}_cxx_std_lib".format(name),
        actions = [
            "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
            "@rules_cc//cc/toolchains/actions:link_actions",
        ],
        args = ["-stdlib={}".format(cxx_std_lib)],
        visibility = visibility,
    )

    cc_args(
        name = "{}_target_triple".format(name),
        actions = [
            "@rules_cc//cc/toolchains/actions:c_compile_actions",
            "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
            "@rules_cc//cc/toolchains/actions:link_actions",
        ],
        args = ["--target={}".format(target_triple)],
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
        "cxx_std_lib": attr.string(mandatory = True, configurable = False),
        "vendor": attr.string(mandatory = True, configurable = False),
        "sysroot": attr.label(mandatory = True, configurable = False),
        "all_tools": attr.label(mandatory = True, configurable = False),
        "target_triple": attr.string(mandatory = True, configurable = False),
    },
    implementation = _declare_toolchain,
)
