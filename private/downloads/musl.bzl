"""Functions for downloading musl sysroot."""

load(":constants.bzl", "DOWNLOAD_BASE_URL")

visibility("//private/...")

def download_musl(rctx, config):
    """Download and extract musl sysroot.

    Args:
      rctx: The repository context.
      config: The configuration dictionary.
    """

    musl_bins_name = "{target}-musl-{musl_version}".format(
        musl_version = config["libc_version"],
        target = config["target"],
    )
    musl_date = RELEASE_TO_DATE[musl_bins_name]

    musl_tarball_name = "{target}-musl-{musl_version}-{musl_date}.tar.xz".format(
        musl_version = config["libc_version"],
        target = config["target"],
        musl_date = musl_date,
    )

    rctx.download_and_extract(
        url = "{release_url}/{tarball_name}".format(
            release_url = DOWNLOAD_BASE_URL,
            tarball_name = musl_tarball_name,
        ),
        sha256 = TARBALL_TO_SHA256[musl_tarball_name],
    )

RELEASE_TO_DATE = {
    "x86_64-linux-musl-musl-1.2.5": "20260220",
}

TARBALL_TO_SHA256 = {
    "x86_64-linux-musl-musl-1.2.5-20260220.tar.xz": "bfaf13affe289e9ba795c268dd34ecefe6b06817b3681adfc7429e4ad7d07334",
}
