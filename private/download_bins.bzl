"""Functions for downloading specific toolchain binaries."""

visibility("//private/...")

def download_bins(rctx, config):
    """Download and extract toolchain binaries and sysroot.

    Args:
      rctx: The lazy_download_bins repository context.
      config: The configuration dictionary.
    """

    # TODO: update to use {host}
    gcc_bins_name = "x86_64-linux-{target}-gcc-{compiler_version}".format(
        compiler_version = config["compiler_version"],
        target = config["target"],
    )
    gcc_date = RELEASE_TO_DATE[gcc_bins_name]

    # TODO: update to use {host}
    gcc_bins_tarball_name = "x86_64-linux-{target}-gcc-{compiler_version}-{gcc_date}.tar.xz".format(
        compiler_version = config["compiler_version"],
        target = config["target"],
        gcc_date = gcc_date,
    )

    # TODO: update to use {host}
    gcc_libs_tarball_name = "{target}-gcc-lib-{compiler_version}-{gcc_date}.tar.xz".format(
        compiler_version = config["compiler_version"],
        target = config["target"],
        gcc_date = gcc_date,
    )

    binutils_bins_name = "x86_64-linux-{target}-binutils-{binutils_version}".format(
        binutils_version = config["binutils_version"],
        target = config["target"],
    )
    binutils_date = RELEASE_TO_DATE[binutils_bins_name]

    # TODO: update to use {host}
    binutils_tarball_name = "x86_64-linux-{target}-binutils-{binutils_version}-{binutils_date}.tar.xz".format(
        binutils_version = config["binutils_version"],
        target = config["target"],
        binutils_date = binutils_date,
    )

    glibc_bins_name = "{target}-glibc-{glibc_version}".format(
        glibc_version = config["libc_version"],
        target = config["target"],
    )
    glibc_date = RELEASE_TO_DATE[glibc_bins_name]

    # TODO: update to use {host}
    glibc_tarball_name = "{target}-glibc-{glibc_version}-{glibc_date}.tar.xz".format(
        glibc_version = config["libc_version"],
        target = config["target"],
        glibc_date = glibc_date,
    )

    linux_headers_name = "x86_64-linux-headers-{linux_headers_version}".format(
        linux_headers_version = config["linux_headers_version"],
    )
    linux_headers_date = RELEASE_TO_DATE[linux_headers_name]

    # TODO: update to use {host}
    linux_headers_tarball_name = "x86_64-linux-headers-{linux_headers_version}-{linux_headers_date}.tar.xz".format(
        linux_headers_version = config["linux_headers_version"],
        linux_headers_date = linux_headers_date,
    )

    rctx.download_and_extract(
        url = "{release_url}/{tarball_name}".format(
            release_url = DOWNLOAD_BASE_URL,
            tarball_name = gcc_bins_tarball_name,
        ),
        sha256 = TARBALL_TO_SHA256[gcc_bins_tarball_name],
    )

    rctx.download_and_extract(
        url = "{release_url}/{tarball_name}".format(
            release_url = DOWNLOAD_BASE_URL,
            tarball_name = gcc_libs_tarball_name,
        ),
        sha256 = TARBALL_TO_SHA256[gcc_libs_tarball_name],
    )

    rctx.download_and_extract(
        url = "{release_url}/{tarball_name}".format(
            release_url = DOWNLOAD_BASE_URL,
            tarball_name = binutils_tarball_name,
        ),
        sha256 = TARBALL_TO_SHA256[binutils_tarball_name],
    )

    rctx.download_and_extract(
        url = "{release_url}/{tarball_name}".format(
            release_url = DOWNLOAD_BASE_URL,
            tarball_name = glibc_tarball_name,
        ),
        sha256 = TARBALL_TO_SHA256[glibc_tarball_name],
    )

    rctx.download_and_extract(
        url = "{release_url}/{tarball_name}".format(
            release_url = DOWNLOAD_BASE_URL,
            tarball_name = linux_headers_tarball_name,
        ),
        sha256 = TARBALL_TO_SHA256[linux_headers_tarball_name],
    )

DOWNLOAD_BASE_URL = "https://github.com/reutermj/toolchains_cc/releases/download/binaries"

RELEASE_TO_DATE = {
    "x86_64-linux-x86_64-linux-gnu-gcc-15.2.0": "20260218",
    "x86_64-linux-x86_64-linux-gnu-binutils-2.45": "20260218",
    "x86_64-linux-gnu-glibc-2.28": "20260218",
    "x86_64-linux-headers-6.18": "20260217",
}

TARBALL_TO_SHA256 = {
    "x86_64-linux-x86_64-linux-gnu-gcc-15.2.0-20260218.tar.xz": "c8b6430de4346fea5acd09689bda4df49783896944655a2ffdad19699498aa8b",
    "x86_64-linux-gnu-gcc-lib-15.2.0-20260218.tar.xz": "12e61d6d4166498a776b01c73866c19cce0506a86b05add8b119c7a45376cd19",
    "x86_64-linux-gnu-glibc-2.28-20260218.tar.xz": "c808d0145434c9fbb273662712c212b99489489396a09b50faa84212f070a9e7",
    "x86_64-linux-x86_64-linux-gnu-binutils-2.45-20260218.tar.xz": "c1f56ffbadc36fc5b74f969e27e6eeca770d62286135f5a1b9ce044cf09135c3",
    "x86_64-linux-headers-6.18-20260217.tar.xz": "34396267a578ef4b81b3951b826c236cf385f7f008bb20b348731ca3318b7c6f",
}
