"""Functions for downloading GCC binaries and libraries."""

load(":constants.bzl", "DOWNLOAD_BASE_URL")

visibility("//private/...")

def download_gcc(rctx, config):
    """Download and extract GCC binaries and libraries.

    Args:
      rctx: The repository context.
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

RELEASE_TO_DATE = {
    "x86_64-linux-x86_64-linux-gnu-gcc-15.2.0": "20260218",
}

TARBALL_TO_SHA256 = {
    "x86_64-linux-x86_64-linux-gnu-gcc-15.2.0-20260218.tar.xz": "c8b6430de4346fea5acd09689bda4df49783896944655a2ffdad19699498aa8b",
    "x86_64-linux-gnu-gcc-lib-15.2.0-20260218.tar.xz": "12e61d6d4166498a776b01c73866c19cce0506a86b05add8b119c7a45376cd19",
}
