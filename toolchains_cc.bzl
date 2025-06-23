load("//impl:alpine.bzl", "extract_alpine")
load("//impl:config.bzl", "get_config_from_env_vars")
load("//impl:host_detect.bzl", "detect_host")
load("//impl:ubuntu.bzl", "extract_ubuntu")

def _lazy_download_bins_impl(rctx):
    """Lazily downloads only the toolchain binaries for the configured platform."""
    config = get_config_from_env_vars(rctx)
    cxx_std_lib = config["cxx_std_lib"]

    if rctx.attr.vendor == "detect":
        host_constants = detect_host(rctx)
        vendor = host_constants["vendor"]

        # buildifier: disable=print
        print("""
Using detected toolchain. Reproduce with:

cc_toolchains.declare(
    name = "{}",
    vendor = "{}",
    cxx_std_lib = "{}",
)
""".format(
            rctx.original_name[:-5],
            vendor,
            cxx_std_lib,
        ))
    else:
        vendor = rctx.attr.vendor

    if vendor == "ubuntu":
        extract_ubuntu(rctx, config)
    elif vendor == "alpine":
        extract_alpine(rctx, config)
    else:
        fail("(toolchains_cc.bzl bug) Unknown vendor: %s" % vendor)

    rctx.download_and_extract(
        url = "https://github.com/reutermj/toolchains_cc.bzl/releases/download/binaries/llvm-19.1.7-linux-x86_64.tar.xz",
    )

    rctx.template(
        "BUILD",
        rctx.attr._build_tpl,
    )

def _eager_declare_toolchain_impl(rctx):
    """Eagerly declare the toolchain(...) to determine which registered toolchain is valid for the current platform."""
    config = get_config_from_env_vars(rctx)

    if rctx.attr.vendor == "detect":
        host_constants = detect_host(rctx)
        target_triple = host_constants["target_triple"]
        vendor = host_constants["vendor"]
    elif rctx.attr.vendor == "ubuntu":
        target_triple = "x86_64-unknown-linux-gnu"
        vendor = "ubuntu"
    elif rctx.attr.vendor == "alpine":
        target_triple = "x86_64-alpine-linux-musl"
        vendor = "alpine"
    else:
        fail("(toolchains_cc.bzl bug) Unknown vendor: %s" % rctx.attr.vendor)

    rctx.template(
        "BUILD",
        rctx.attr._build_tpl,
        substitutions = {
            "%{toolchain_name}": rctx.original_name,
            "%{cxx_std_lib}": config["cxx_std_lib"],
            "%{target_triple}": target_triple,
            "%{bins_repo_name}": rctx.name + "_bins",
            "%{vendor}": vendor,
        },
    )

_lazy_download_bins = repository_rule(
    implementation = _lazy_download_bins_impl,
    attrs = {
        "vendor": attr.string(
            mandatory = False,
            doc = "The vendor of the target platform. Also determines the libc.",
            values = [
                "detect",
                "ubuntu",
                "alpine",
            ],
            default = "detect",
        ),
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
        "vendor": attr.string(
            mandatory = False,
            doc = "The vendor of the target platform. Also determines the libc.",
            values = [
                "detect",
                "ubuntu",
                "alpine",
            ],
            default = "detect",
        ),
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
            if declared_toolchain.vendor == "windows" and not declared_toolchain.accept_winsdk_license:
                fail(
                    """
Please view the Microsoft Visual Studio License terms: https://go.microsoft.com/fwlink/?LinkId=2086102.
Accept the license by setting `accept_winsdk_license = True` in your toolchain declaration:
cc_toolchains.declare(
    name = "{}",
    vendor = "{}",
    accept_winsdk_license = True,
)
""".format(
                        declared_toolchain.name,
                        declared_toolchain.vendor,
                        declared_toolchain.cxx_std_lib,
                    ),
                )

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
            _eager_declare_toolchain(
                name = declared_toolchain.name,
                vendor = declared_toolchain.vendor,
                toolchain_name = declared_toolchain.name,
            )
            _lazy_download_bins(
                name = declared_toolchain.name + "_bins",
                vendor = declared_toolchain.vendor,
                toolchain_name = declared_toolchain.name,
            )

cxx_toolchains = module_extension(
    implementation = _cxx_toolchains,
    tag_classes = {
        "declare": tag_class(
            attrs = {
                "accept_winsdk_license": attr.bool(
                    default = False,
                ),
                "name": attr.string(
                    mandatory = True,
                    doc = "The name of the toolchain, used for registration.",
                ),
                "vendor": attr.string(
                    mandatory = False,
                    doc = "The vendor of the target platform. Also determines the libc.",
                    values = [
                        "detect",
                        "ubuntu",
                        "alpine",
                    ],
                    default = "detect",
                ),
            },
        ),
    },
)
