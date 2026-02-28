"""Functions for downloading binutils binaries."""

load(":constants.bzl", "DOWNLOAD_BASE_URL", "get_host")

visibility("//private/...")

def download_binutils(rctx, config):
    """Download and extract binutils binaries.

    Args:
      rctx: The repository context.
      config: The configuration dictionary.
    """

    host = get_host(config)

    binutils_bins_name = "{host}-{target}-binutils-{binutils_version}".format(
        host = host,
        binutils_version = config["binutils_version"],
        target = config["target"],
    )
    binutils_date = RELEASE_TO_DATE[binutils_bins_name]

    binutils_tarball_name = "{host}-{target}-binutils-{binutils_version}-{binutils_date}.tar.xz".format(
        host = host,
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
    "x86_64-linux-x86_64-linux-musl-binutils-2.45": "20260219",
    "aarch64-linux-aarch64-linux-gnu-binutils-2.45": "20260228",
}

TARBALL_TO_SHA256 = {
    "x86_64-linux-x86_64-linux-gnu-binutils-2.45-20260218.tar.xz": "c1f56ffbadc36fc5b74f969e27e6eeca770d62286135f5a1b9ce044cf09135c3",
    "x86_64-linux-x86_64-linux-musl-binutils-2.45-20260219.tar.xz": "b68e2adae65d6eb22fbeb161acca652cae6eb5413581bcfa953072e1bbf9d79b",
    "aarch64-linux-aarch64-linux-gnu-binutils-2.45-20260228.tar.xz": "a0ec2a34a8f084911c747543b0dd54c62759990b46ea022e67a9c2c8c5a48e61",
}
