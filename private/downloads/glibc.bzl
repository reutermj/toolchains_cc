"""Functions for downloading glibc sysroot."""

load(":constants.bzl", "DOWNLOAD_BASE_URL")

visibility("//private/...")

def download_glibc(rctx, config):
    """Download and extract glibc sysroot.

    Args:
      rctx: The repository context.
      config: The configuration dictionary.
    """

    glibc_bins_name = "{target}-glibc-{glibc_version}".format(
        glibc_version = config["libc_version"],
        target = config["target"],
    )
    glibc_date = RELEASE_TO_DATE[glibc_bins_name]

    glibc_tarball_name = "{target}-glibc-{glibc_version}-{glibc_date}.tar.xz".format(
        glibc_version = config["libc_version"],
        target = config["target"],
        glibc_date = glibc_date,
    )

    rctx.download_and_extract(
        url = "{release_url}/{tarball_name}".format(
            release_url = DOWNLOAD_BASE_URL,
            tarball_name = glibc_tarball_name,
        ),
        sha256 = TARBALL_TO_SHA256[glibc_tarball_name],
    )

RELEASE_TO_DATE = {
    "x86_64-linux-gnu-glibc-2.28": "20260218",
    "aarch64-linux-gnu-glibc-2.28": "20260228",
}

TARBALL_TO_SHA256 = {
    "x86_64-linux-gnu-glibc-2.28-20260218.tar.xz": "c808d0145434c9fbb273662712c212b99489489396a09b50faa84212f070a9e7",
    "aarch64-linux-gnu-glibc-2.28-20260228.tar.xz": "28a46420f38d2f975544f24ee70cedd45c698abed32e567eaa60db0eeb4364b0",
}
