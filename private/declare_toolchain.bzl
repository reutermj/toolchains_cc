"""Macro for declaring the toolchain metadata inside the eager_declare_toolchain repo rule."""

load("@rules_cc//cc/toolchains:args.bzl", "cc_args")
load("@rules_cc//cc/toolchains:toolchain.bzl", "cc_toolchain")

_TARGET_TO_CPU_CONSTRAINT = {
    "x86_64": "@platforms//cpu:x86_64",
    "aarch64": "@platforms//cpu:aarch64",
}

def declare_toolchain(name, visibility, sysroot, all_tools, compiler, target):
    """Declares a cc_toolchain with the given parameters.

    Args:
        name: Name of the toolchain
        visibility: Visibility of the toolchain
        sysroot: Label for the sysroot subdirectory target
        all_tools: Tool map for the toolchain
        compiler: Compiler type
        target: Target triple (e.g., x86_64-linux-gnu, aarch64-linux-gnu)
    """
    args = []
    # ==================================
    # || Declare General Purpose Args ||
    # ==================================

    # Bazel does not like absolute paths.
    # Clang and GCC will use absolute paths when reporting the include path for its headers causing bazel to error out.
    # This changes the toolchains to use relative paths.
    # Symptom:
    # ERROR: C:/users/mark/desktop/new_toolchain/BUILD:1:10: Compiling main.c failed: absolute path inclusion(s) found in rule '//:main':
    # the source file 'main.c' includes the following non-builtin files with absolute paths (if these are builtin files, make sure these paths are in your toolchain):
    #   'C:/Users/mark/_bazel_mark/w77p7fta/external/+_repo_rules+llvm_toolchain/toolchain/lib/clang/19/include/vadefs.h'
    no_canonical_prefixes_arg = "{}_no_canonical_prefixes".format(name)
    args.append(no_canonical_prefixes_arg)
    cc_args(
        name = no_canonical_prefixes_arg,
        actions = [
            "@rules_cc//cc/toolchains/actions:c_compile",
            "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
            "@rules_cc//cc/toolchains/actions:assembly_actions",
            "@rules_cc//cc/toolchains/actions:link_actions",
        ],
        args = [
            "-no-canonical-prefixes",
        ],
        visibility = ["//visibility:private"],
    )

    sysroot_arg = "{}_sysroot".format(name)
    args.append(sysroot_arg)
    cc_args(
        name = sysroot_arg,
        actions = [
            "@rules_cc//cc/toolchains/actions:c_compile",
            "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
            "@rules_cc//cc/toolchains/actions:assembly_actions",
            "@rules_cc//cc/toolchains/actions:link_actions",
        ],
        args = ["--sysroot={sysroot}"],
        format = {
            "sysroot": sysroot,
        },
        visibility = ["//visibility:private"],
    )

    # glibc uses feature test macros to control which functions are visible in headers.
    # Linux code commonly uses GNU extensions that glibc hides behind these macros.
    # Without `_GNU_SOURCE`, glibc headers hide functions like futimesat(), pipe2(),
    # and accept4(), causing "implicit declaration of function" errors.
    # This defines `_GNU_SOURCE` to expose the full glibc API (POSIX, X/Open, GNU).
    # https://www.gnu.org/software/libc/manual/html_node/Feature-Test-Macros.html
    gnu_source_arg = "{}_gnu_source".format(name)
    args.append(gnu_source_arg)
    cc_args(
        name = gnu_source_arg,
        actions = [
            "@rules_cc//cc/toolchains/actions:c_compile",
            "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
        ],
        args = ["-D_GNU_SOURCE"],
        visibility = ["//visibility:private"],
    )

    # =====================================
    # || Declare Toolchain Specific Args ||
    # =====================================
    if compiler == "gcc":
        no_canonical_system_headers_arg = "{}_no_canonical_system_headers".format(name)
        args.append(no_canonical_system_headers_arg)
        cc_args(
            name = no_canonical_system_headers_arg,
            actions = [
                "@rules_cc//cc/toolchains/actions:c_compile",
                "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
                "@rules_cc//cc/toolchains/actions:assembly_actions",
                "@rules_cc//cc/toolchains/actions:link_actions",
            ],
            args = [
                "-fno-canonical-system-headers",
            ],
            visibility = ["//visibility:private"],
        )
    elif compiler == "llvm":
        pass
    else:
        fail("[toolchains_cc bug] Failed to handle a supported compiler: {}".format(compiler))

    # =======================
    # || Declare Toolchain ||
    # =======================
    arch = target.split("-")[0]
    cpu_constraint = _TARGET_TO_CPU_CONSTRAINT[arch]

    native.toolchain(
        name = name,
        exec_compatible_with = [
            "@platforms//os:linux",
            cpu_constraint,
        ],
        target_compatible_with = [
            "@platforms//os:linux",
            cpu_constraint,
        ],
        toolchain = ":{}_cc_toolchain".format(name),
        toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
        visibility = visibility,
    )

    cc_toolchain(
        name = "{}_cc_toolchain".format(name),
        args = args,
        enabled_features = ["@rules_cc//cc/toolchains/args:experimental_replace_legacy_action_config_features"],
        known_features = ["@rules_cc//cc/toolchains/args:experimental_replace_legacy_action_config_features"],
        tool_map = all_tools,
        visibility = ["//visibility:private"],
    )

# TODO: currently the cc_toolchain macro produces targets whose names dont follow the rules of symbolic macros
# see: https://github.com/bazelbuild/rules_cc/pull/487
# declare_toolchain = macro(
#     attrs = {
#         # configurable = False is required because macros wrap configurable attrs in
#         # a select(...) which cant be used when inlining the labels and strings in
#         # the toolchain declarations.
#         "sysroot": attr.label(mandatory = True, configurable = False),
#         "all_tools": attr.label(mandatory = True, configurable = False),
#     },
#     implementation = _declare_toolchain,
# )
