"""Functions for downloading LLVM and libclang binaries."""

load(":constants.bzl", "DOWNLOAD_BASE_URL", "get_host")

visibility("//private/...")

def download_llvm(rctx, config):
    """Download and extract LLVM toolchain binaries and libclang libraries.

    Args:
      rctx: The repository context.
      config: The configuration dictionary.
    """

    host = get_host(config)

    llvm_bins_name = "{host}-llvm-{compiler_version}".format(
        host = host,
        compiler_version = config["compiler_version"],
    )
    llvm_date = RELEASE_TO_DATE[llvm_bins_name]

    llvm_bins_tarball_name = "{host}-llvm-{compiler_version}-{llvm_date}.tar.xz".format(
        host = host,
        compiler_version = config["compiler_version"],
        llvm_date = llvm_date,
    )

    libclang_tarball_name = "{host}-libclang-{compiler_version}-{llvm_date}.tar.xz".format(
        host = host,
        compiler_version = config["compiler_version"],
        llvm_date = llvm_date,
    )

    rctx.download_and_extract(
        url = "{release_url}/{tarball_name}".format(
            release_url = DOWNLOAD_BASE_URL,
            tarball_name = llvm_bins_tarball_name,
        ),
        sha256 = TARBALL_TO_SHA256[llvm_bins_tarball_name],
    )

    rctx.download_and_extract(
        url = "{release_url}/{tarball_name}".format(
            release_url = DOWNLOAD_BASE_URL,
            tarball_name = libclang_tarball_name,
        ),
        sha256 = TARBALL_TO_SHA256[libclang_tarball_name],
    )

RELEASE_TO_DATE = {
    "x86_64-linux-llvm-21.1.1": "20260222",
}

TARBALL_TO_SHA256 = {
    "x86_64-linux-llvm-21.1.1-20260222.tar.xz": "f5c2e07af6aa477f97aa452d9c2ce5282d28e57be3d54827de8d8ccba3f5e8e2",
    "x86_64-linux-libclang-21.1.1-20260222.tar.xz": "3e03ec5c2e6fb029f01d11a5f59316883ab33d2780e4b168f9eb039e1a03e5c9",
}
