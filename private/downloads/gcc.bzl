"""Functions for downloading GCC binaries and libraries."""

load(":constants.bzl", "DOWNLOAD_BASE_URL", "get_host")

visibility("//private/...")

def download_gcc(rctx, config):
    """Download and extract GCC binaries and libraries.

    Args:
      rctx: The repository context.
      config: The configuration dictionary.
    """

    host = get_host(config)

    gcc_bins_name = "{host}-{target}-gcc-{compiler_version}".format(
        host = host,
        compiler_version = config["compiler_version"],
        target = config["target"],
    )
    gcc_date = RELEASE_TO_DATE[gcc_bins_name]

    gcc_bins_tarball_name = "{host}-{target}-gcc-{compiler_version}-{gcc_date}.tar.xz".format(
        host = host,
        compiler_version = config["compiler_version"],
        target = config["target"],
        gcc_date = gcc_date,
    )

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
    "x86_64-linux-x86_64-linux-gnu-gcc-15.2.0": "20260222",
    "x86_64-linux-x86_64-linux-musl-gcc-15.2.0": "20260222",
    "aarch64-linux-aarch64-linux-gnu-gcc-15.2.0": "20260228",
}

TARBALL_TO_SHA256 = {
    "x86_64-linux-x86_64-linux-gnu-gcc-15.2.0-20260222.tar.xz": "4a9f7d799aa96efe06ae362f85d87586fabbae619a82c565294d9971717cf0e4",
    "x86_64-linux-gnu-gcc-lib-15.2.0-20260222.tar.xz": "372c953c9cd8455b2fc541b33ad790622665efc17b4bf128f52f4844c9c6ed1e",
    "x86_64-linux-x86_64-linux-musl-gcc-15.2.0-20260222.tar.xz": "940c7e9f4bf88838eb2497f1073b203877c86dc8efae5fc6311dc5e517ec6c56",
    "x86_64-linux-musl-gcc-lib-15.2.0-20260222.tar.xz": "90e1049836ff83ae44e6c7cb0cd14d83913ea5963516e9131ed46dfc1e44d3e9",
    "aarch64-linux-aarch64-linux-gnu-gcc-15.2.0-20260228.tar.xz": "56103e50a905906ea78b0a4e291b4c3fb92b2a182cc3b185b55229d3323b219a",
    "aarch64-linux-gnu-gcc-lib-15.2.0-20260228.tar.xz": "93951d47eb9aa4d31e0167ab015d98b688d919659577573fae636ddb3c806559",
}
