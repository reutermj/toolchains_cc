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
    "x86_64-linux-gnu-glibc-2.29": "20260311",
    "aarch64-linux-gnu-glibc-2.29": "20260311",
    "x86_64-linux-gnu-glibc-2.30": "20260311",
    "aarch64-linux-gnu-glibc-2.30": "20260311",
}

TARBALL_TO_SHA256 = {
    "x86_64-linux-gnu-glibc-2.28-20260218.tar.xz": "c808d0145434c9fbb273662712c212b99489489396a09b50faa84212f070a9e7",
    "aarch64-linux-gnu-glibc-2.28-20260228.tar.xz": "28a46420f38d2f975544f24ee70cedd45c698abed32e567eaa60db0eeb4364b0",
    "x86_64-linux-gnu-glibc-2.29-20260311.tar.xz": "04b3e173d1f1f9bd7cc18ebe65f37bcda934b4c8f85ee24f7cf8de1f7ef96ab4",
    "aarch64-linux-gnu-glibc-2.29-20260311.tar.xz": "af89007391be9ad68be00445d2b0de50d0e0ab422435cc27800307b3ce26787d",
    "x86_64-linux-gnu-glibc-2.30-20260311.tar.xz": "66fa79ae6974f1c9b8048501830473c55ebf05ae8510a671aee232351a496ce1",
    "aarch64-linux-gnu-glibc-2.30-20260311.tar.xz": "2d4d2f27559dec5f95415e3dd7bb5e4ee3ddb36516f1b969214cadd66a365cf4",
}
