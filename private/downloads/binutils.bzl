"""Functions for downloading binutils binaries."""

load(":constants.bzl", "DOWNLOAD_BASE_URL")

visibility("//private/...")

def download_binutils(rctx, config):
    """Download and extract binutils binaries.

    Args:
      rctx: The repository context.
      config: The configuration dictionary.
    """

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

    rctx.download_and_extract(
        url = "{release_url}/{tarball_name}".format(
            release_url = DOWNLOAD_BASE_URL,
            tarball_name = binutils_tarball_name,
        ),
        sha256 = TARBALL_TO_SHA256[binutils_tarball_name],
    )

RELEASE_TO_DATE = {
    "x86_64-linux-x86_64-linux-gnu-binutils-2.45": "20260218",
}

TARBALL_TO_SHA256 = {
    "x86_64-linux-x86_64-linux-gnu-binutils-2.45-20260218.tar.xz": "c1f56ffbadc36fc5b74f969e27e6eeca770d62286135f5a1b9ce044cf09135c3",
}
