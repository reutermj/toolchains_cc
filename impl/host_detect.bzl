"""Utilities for detecting features of the host platform."""

visibility(["//..."])

def _detect_host(rctx):
    result = rctx.execute(["ldd", "--version"])

    ldd_output = result.stdout.lower()
    if ldd_output.find("glibc") != -1:
        # vendor = "glibc"
        vendor = "ubuntu"
        target_triple = "x86_64-unknown-linux-gnu"

        # This assumes that the output of ldd for glibc based systems is formatted like:
        # ldd (<distro> GLIBC <distro libc version>) <libc version>
        libc_version = ldd_output.splitlines()[0].split(" ")[-1].strip()
    elif ldd_output.find("musl") != -1:
        # vendor = "musl"
        vendor = "alpine"
        target_triple = "x86_64-alpine-linux-musl"

        # musl libc (<arch>)
        # Version <libc version>
        libc_version = ldd_output.splitlines()[1].split(" ")[-1].strip()
    else:
        fail("(toolchains_cc.bzl bug) Unknown libc: %s" % ldd_output)

    return {
        "vendor": vendor,
        "libc_version": libc_version,
        "target_triple": target_triple,
    }

def _detect_host_platform_impl(rctx):
    host_constants = _detect_host(rctx)

    rctx.file("BUILD")
    rctx.file(
        "platform_constants.bzl",
        content = """VENDOR = "{}"
LIBC_VERSION = "{}"
TRIPLE = "{}"
""".format(
            host_constants["vendor"],
            host_constants["libc_version"],
            host_constants["target_triple"],
        ),
    )

detect_host_platform = repository_rule(
    implementation = _detect_host_platform_impl,
)
