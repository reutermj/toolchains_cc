"""Entrypoint for declaring C/C++ toolchains using toolchains_cc."""

load("//private:eager_declare_toolchain.bzl", "eager_declare_toolchain")
load("//private:lazy_download_bins.bzl", "lazy_download_bins")

# Why are we using a module extension + two repo rules?
# toolchains_cc should only download the toolchain binaries for the toolchain that is actually used. For example, a user
# might want to have a polyglot repo with both C and Python code, and when they're just building the Python code,
# toolchains_cc shouldn't block the user by performing the expensive binary downloads. If only one repo rule was used
# to both declare the toolchain and download the toolchain binaries, then it would be impossible to register the
# toolchain without also downloading the binaries. This problem is solved by using two repo rules: one to declare the
# toolchain and another to download the toolchain binaries. The first is eagerly fetched when the toolchain is
# registered, and the second is fetched only when the toolchain is actually used to compile C/C++ code. The module
# extension must be used here because a repo rule isn't allowed to invoke another repo rule.
_CONFIG_KEYS = ["target", "libc_version", "binutils_version", "compiler", "compiler_version", "linux_headers_version"]

def _cc_toolchains(module_ctx):
    for mod in module_ctx.modules:
        for declared_toolchain in mod.tags.declare:
            toolchain_name = declared_toolchain.name

            config_overrides = {}
            for key in _CONFIG_KEYS:
                val = getattr(declared_toolchain, key)
                if val:
                    config_overrides[key] = val

            eager_declare_toolchain(
                name = declared_toolchain.name,
                toolchain_name = toolchain_name,
                config_overrides = config_overrides,
            )
            lazy_download_bins(
                name = declared_toolchain.name + "_bins",
                toolchain_name = toolchain_name,
                config_overrides = config_overrides,
            )

cc_toolchains = module_extension(
    implementation = _cc_toolchains,
    tag_classes = {
        "declare": tag_class(
            attrs = {
                "name": attr.string(
                    mandatory = True,
                    doc = "The name of the toolchain, used for registration.",
                ),
                "target": attr.string(
                    doc = "Target triple (e.g. x86_64-linux-gnu, x86_64-linux-musl). Overridden by --repo_env.",
                ),
                "libc_version": attr.string(
                    doc = "Libc version (e.g. 2.28). Overridden by --repo_env.",
                ),
                "binutils_version": attr.string(
                    doc = "Binutils version (e.g. 2.45). Overridden by --repo_env.",
                ),
                "compiler": attr.string(
                    doc = "Compiler type (e.g. gcc). Overridden by --repo_env.",
                ),
                "compiler_version": attr.string(
                    doc = "Compiler version (e.g. 15.2.0). Overridden by --repo_env.",
                ),
                "linux_headers_version": attr.string(
                    doc = "Linux kernel headers version (e.g. 6.18). Overridden by --repo_env.",
                ),
            },
        ),
    },
)
