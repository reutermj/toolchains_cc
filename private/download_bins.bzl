"""Functions for downloading specific toolchain binaries."""

visibility("//private/...")

def download_bins(rctx, config):
    """Download and extract toolchain binaries and sysroot.

    Args:
      rctx: The lazy_download_bins repository context.
      config: The configuration dictionary.
    """
    release_name = "{target}-{libc_version}-gcc-{compiler_version}".format(
        compiler_version = config["compiler_version"],
        target = config["target"],
        libc_version = config["libc_version"],
    )
    release_date = RELEASE_TO_DATE[release_name]

    release_url = "{base_url}/{release_name}-{release_date}".format(
        base_url = DOWNLOAD_BASE_URL,
        release_name = release_name,
        release_date = release_date,
    )

    tarball_name = "{target}-{libc_version}-gcc-{compiler_version}-{release_date}.tar.xz".format(
        compiler_version = config["compiler_version"],
        target = config["target"],
        libc_version = config["libc_version"],
        release_date = release_date,
    )

    rctx.download_and_extract(
        url = "{release_url}/{tarball_name}".format(
            release_url = release_url,
            tarball_name = tarball_name,
        ),
        sha256 = TARBALL_TO_SHA256[tarball_name],
    )

DOWNLOAD_BASE_URL = "https://github.com/reutermj/toolchains_cc/releases/download"

RELEASE_TO_DATE = {
    "x86_64-linux-gnu-2.28-gcc-15.2.0": "20250917",
    "x86_64-linux-gnu-2.29-gcc-15.2.0": "20250917",
    "x86_64-linux-gnu-2.30-gcc-15.2.0": "20250917",
    "x86_64-linux-gnu-2.31-gcc-15.2.0": "20250917",
    "x86_64-linux-gnu-2.32-gcc-15.2.0": "20250917",
    "x86_64-linux-gnu-2.33-gcc-15.2.0": "20250917",
    "x86_64-linux-gnu-2.34-gcc-15.2.0": "20250917",
    "x86_64-linux-gnu-2.35-gcc-15.2.0": "20250917",
    "x86_64-linux-gnu-2.36-gcc-15.2.0": "20250917",
    "x86_64-linux-gnu-2.37-gcc-15.2.0": "20250917",
    "x86_64-linux-gnu-2.38-gcc-15.2.0": "20250917",
    "x86_64-linux-gnu-2.39-gcc-15.2.0": "20250917",
    "x86_64-linux-gnu-2.40-gcc-15.2.0": "20250917",
    "x86_64-linux-gnu-2.41-gcc-15.2.0": "20250917",
    "x86_64-linux-gnu-2.42-gcc-15.2.0": "20250917",
}

TARBALL_TO_SHA256 = {
    "x86_64-linux-gnu-2.28-gcc-15.2.0-20250917.tar.xz": "8682c5ba40e75e735e4cc33fb6de413af5233482f2460b0a9eefbf6366f8fede",
    "x86_64-linux-gnu-2.29-gcc-15.2.0-20250917.tar.xz": "55eb640906968edcec2e043e44771235e0783d79ed7e439bb6c8f6cccda1eb9b",
    "x86_64-linux-gnu-2.30-gcc-15.2.0-20250917.tar.xz": "15e5ca6f03d1b013f3fe5ac8b0d192b4c6339df8c8af1852140bea67e7fc15e1",
    "x86_64-linux-gnu-2.31-gcc-15.2.0-20250917.tar.xz": "b3e4784c752339fcad86a37aacb17271a85d32c5711b1315c564ca08a713313a",
    "x86_64-linux-gnu-2.32-gcc-15.2.0-20250917.tar.xz": "68f2e5df14c4885144b465429aa9afd9fd6f195cb232ecce1ce98c7a50216021",
    "x86_64-linux-gnu-2.33-gcc-15.2.0-20250917.tar.xz": "13728e061c17723afde1edb04a1a7221db9c459bf8fcdfec6b098040794af1ec",
    "x86_64-linux-gnu-2.34-gcc-15.2.0-20250917.tar.xz": "9b725d3ea0a5a57d0c8b6792c7fdd4b87c956e016761887fe814f91abc0924a9",
    "x86_64-linux-gnu-2.35-gcc-15.2.0-20250917.tar.xz": "9d529f07b7687982e858649e57322f66d847ac725221211d04f7ec93750db4bc",
    "x86_64-linux-gnu-2.36-gcc-15.2.0-20250917.tar.xz": "dd1f0c0b86de4ec2d18b9eda014dd7883d18a8e50fa388c859a9071f163a31bb",
    "x86_64-linux-gnu-2.37-gcc-15.2.0-20250917.tar.xz": "857d1d17f9a50d88aeb8390f70faa07d9cdf2e65a131039d1e27f4d34d849068",
    "x86_64-linux-gnu-2.38-gcc-15.2.0-20250917.tar.xz": "031331a0051d4f334c643b0f0bbfdf8025ce37f7619db38b0525cd88324c9370",
    "x86_64-linux-gnu-2.39-gcc-15.2.0-20250917.tar.xz": "86856b95818ff41454e4f6097507136a085fbb8990d832d2030aa3f434e66770",
    "x86_64-linux-gnu-2.40-gcc-15.2.0-20250917.tar.xz": "e790919dfee8a139bf5900c930b65f7b37064268f7dd5ae8b71db1f44d5d9156",
    "x86_64-linux-gnu-2.41-gcc-15.2.0-20250917.tar.xz": "5e61350d827b983c214384f519ecd84deb713639ccc542d610f3534062e213f6",
    "x86_64-linux-gnu-2.42-gcc-15.2.0-20250917.tar.xz": "0db82980827155fef787c795b061c3cad64ab917efd9998d98eea6bda4e478ce",
}
