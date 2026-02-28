"""Functions for downloading Linux kernel headers."""

load(":constants.bzl", "DOWNLOAD_BASE_URL", "get_host")

visibility("//private/...")

def download_linux_headers(rctx, config):
    """Download and extract Linux kernel headers.

    Args:
      rctx: The repository context.
      config: The configuration dictionary.
    """

    host = get_host(config)
    arch = host.split("-")[0]

    linux_headers_name = "{arch}-linux-headers-{linux_headers_version}".format(
        arch = arch,
        linux_headers_version = config["linux_headers_version"],
    )
    linux_headers_date = RELEASE_TO_DATE[linux_headers_name]

    linux_headers_tarball_name = "{arch}-linux-headers-{linux_headers_version}-{linux_headers_date}.tar.xz".format(
        arch = arch,
        linux_headers_version = config["linux_headers_version"],
        linux_headers_date = linux_headers_date,
    )

    rctx.download_and_extract(
        url = "{release_url}/{tarball_name}".format(
            release_url = DOWNLOAD_BASE_URL,
            tarball_name = linux_headers_tarball_name,
        ),
        sha256 = TARBALL_TO_SHA256[linux_headers_tarball_name],
    )

RELEASE_TO_DATE = {
    "x86_64-linux-headers-6.18": "20260217",
    "aarch64-linux-headers-6.18": "20260228",
}

TARBALL_TO_SHA256 = {
    "x86_64-linux-headers-6.18-20260217.tar.xz": "34396267a578ef4b81b3951b826c236cf385f7f008bb20b348731ca3318b7c6f",
    "aarch64-linux-headers-6.18-20260228.tar.xz": "dafd326fe1df8fce64805b420666606f984a76087563e36c4ff69cb5e323751a",
}
