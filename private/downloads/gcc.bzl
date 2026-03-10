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
    "x86_64-linux-x86_64-linux-gnu-gcc-11.5.0": "20260310",
    "x86_64-linux-x86_64-linux-musl-gcc-11.5.0": "20260310",
    "x86_64-linux-x86_64-linux-gnu-gcc-12.5.0": "20260310",
    "x86_64-linux-x86_64-linux-musl-gcc-12.5.0": "20260306",
    "x86_64-linux-x86_64-linux-gnu-gcc-13.4.0": "20260306",
    "x86_64-linux-x86_64-linux-musl-gcc-13.4.0": "20260306",
    "x86_64-linux-x86_64-linux-gnu-gcc-14.2.0": "20260305",
    "x86_64-linux-x86_64-linux-musl-gcc-14.2.0": "20260305",
    "x86_64-linux-x86_64-linux-gnu-gcc-15.2.0": "20260222",
    "x86_64-linux-x86_64-linux-musl-gcc-15.2.0": "20260222",
    "aarch64-linux-aarch64-linux-gnu-gcc-11.5.0": "20260310",
    "aarch64-linux-aarch64-linux-musl-gcc-11.5.0": "20260310",
    "aarch64-linux-aarch64-linux-gnu-gcc-12.5.0": "20260310",
    "aarch64-linux-aarch64-linux-musl-gcc-12.5.0": "20260310",
    "aarch64-linux-aarch64-linux-gnu-gcc-13.4.0": "20260310",
    "aarch64-linux-aarch64-linux-musl-gcc-13.4.0": "20260310",
    "aarch64-linux-aarch64-linux-gnu-gcc-14.2.0": "20260310",
    "aarch64-linux-aarch64-linux-musl-gcc-14.2.0": "20260310",
    "aarch64-linux-aarch64-linux-gnu-gcc-15.2.0": "20260228",
    "aarch64-linux-aarch64-linux-musl-gcc-15.2.0": "20260228",
}

TARBALL_TO_SHA256 = {
    "x86_64-linux-x86_64-linux-gnu-gcc-11.5.0-20260310.tar.xz": "d8c3e210c27191cfd2b385ebd67dabb0b4f7b1c3d5ee4340d2fe121161112dba",
    "x86_64-linux-gnu-gcc-lib-11.5.0-20260310.tar.xz": "4662995938bf7b39d0ca1486b9dad9b236345ccf915ba4fcd5e4bb16d0a33582",
    "x86_64-linux-x86_64-linux-musl-gcc-11.5.0-20260310.tar.xz": "a2379ae82c7fca5ad2e308e2fe5e783f5d3cbfdb73e7aea43d21bb3939c391bc",
    "x86_64-linux-musl-gcc-lib-11.5.0-20260310.tar.xz": "e470e7383171084c0295db8ddd4b7ff3267c81c43f0d2a3ac256ac1421511d22",
    "x86_64-linux-x86_64-linux-gnu-gcc-12.5.0-20260310.tar.xz": "426c3d28aa5d1701f0a667545c09a8a1dbcef9a76f7294cfd9a42feeea8d6f19",
    "x86_64-linux-gnu-gcc-lib-12.5.0-20260310.tar.xz": "f5f8a2ba506ad3e8c11501b43e7efe09fd03511a5c47ddc9a34711b56e7f0edb",
    "x86_64-linux-x86_64-linux-musl-gcc-12.5.0-20260306.tar.xz": "5513705c97351b9ea32bf1fe3057c24717a2e45b055d3dff78600be027de92c9",
    "x86_64-linux-musl-gcc-lib-12.5.0-20260306.tar.xz": "c56a1fbc196cc3ad7886aeda2afad8c86e14e5c55615bd81cc98d0045615ff20",
    "x86_64-linux-x86_64-linux-gnu-gcc-13.4.0-20260306.tar.xz": "759e83721f05f7d6901f486d76de08750230dafc2eaf5de13d1c551b5d12aa14",
    "x86_64-linux-gnu-gcc-lib-13.4.0-20260306.tar.xz": "54dcd554f6ed59f5a23a6e9f80d68b2e266f947ce0ef8e7c99b631fdc39c890a",
    "x86_64-linux-x86_64-linux-musl-gcc-13.4.0-20260306.tar.xz": "438cb07d8b9f844b5702a904a07db7e6f8681fca1b418200fd45947a7be701e5",
    "x86_64-linux-musl-gcc-lib-13.4.0-20260306.tar.xz": "9075bb17195924a3cdd5820b261ed20c30442b7afa9c22aabe129627c24b49af",
    "x86_64-linux-x86_64-linux-gnu-gcc-14.2.0-20260305.tar.xz": "050141f79deba9f627804195915b4ecf46fcb534f3a172cc7346f50d6e796d2d",
    "x86_64-linux-gnu-gcc-lib-14.2.0-20260305.tar.xz": "c6c92472db1c3578bf5c86b78115abbc9e745bd0e7f7d211bf0c158e3f99c29e",
    "x86_64-linux-x86_64-linux-musl-gcc-14.2.0-20260305.tar.xz": "0c7e9319e1088d5ac871e01aff6d255a98b7b3e06ad61cd8b533910af1f10fc2",
    "x86_64-linux-musl-gcc-lib-14.2.0-20260305.tar.xz": "6d9dcc69c953b14db4f42c2f87c596c464abdeb12b0ae86d23dda969a4477597",
    "x86_64-linux-x86_64-linux-gnu-gcc-15.2.0-20260222.tar.xz": "4a9f7d799aa96efe06ae362f85d87586fabbae619a82c565294d9971717cf0e4",
    "x86_64-linux-gnu-gcc-lib-15.2.0-20260222.tar.xz": "372c953c9cd8455b2fc541b33ad790622665efc17b4bf128f52f4844c9c6ed1e",
    "x86_64-linux-x86_64-linux-musl-gcc-15.2.0-20260222.tar.xz": "940c7e9f4bf88838eb2497f1073b203877c86dc8efae5fc6311dc5e517ec6c56",
    "x86_64-linux-musl-gcc-lib-15.2.0-20260222.tar.xz": "90e1049836ff83ae44e6c7cb0cd14d83913ea5963516e9131ed46dfc1e44d3e9",
    "aarch64-linux-aarch64-linux-gnu-gcc-11.5.0-20260310.tar.xz": "1f491d403f1a99b9b3dfdb2f82f95857a99875c1a64607a48ca61758747d48b1",
    "aarch64-linux-gnu-gcc-lib-11.5.0-20260310.tar.xz": "422752896b89530519aafa600cd685d8af2392db5909954b1e6949301ae05e87",
    "aarch64-linux-aarch64-linux-musl-gcc-11.5.0-20260310.tar.xz": "b0ff0302811781c73b8d48b896db21e3ced46cea19a3b820a9d22f22c0a1ee3d",
    "aarch64-linux-musl-gcc-lib-11.5.0-20260310.tar.xz": "9067aaa4cbf42e4e13935cf24f30ab95e18dd5fd045ab13ed083cfece63beeb2",
    "aarch64-linux-aarch64-linux-gnu-gcc-12.5.0-20260310.tar.xz": "aa6d4b29499dc235fe21b7a5889613a03388fbf58bcc66c9b43bf1a2c93eb99c",
    "aarch64-linux-gnu-gcc-lib-12.5.0-20260310.tar.xz": "f4d512a17954ede3671c84c7a3b805b7621c1416dc44ac6c57a668cb2e33e5d8",
    "aarch64-linux-aarch64-linux-musl-gcc-12.5.0-20260310.tar.xz": "fc443f2eb5fe111aa0617ffe42505e8d8223d45ce68af128faf45c34f2834f35",
    "aarch64-linux-musl-gcc-lib-12.5.0-20260310.tar.xz": "f2b9a2408bca252f0ccbe605c54cb327b23c124c9218699834916347dfbff79c",
    "aarch64-linux-aarch64-linux-gnu-gcc-13.4.0-20260310.tar.xz": "cd3ed8dd88e7d28da3e6d810f6b3e7b8d8adb21fb95368e61a14e8ab72bd085b",
    "aarch64-linux-gnu-gcc-lib-13.4.0-20260310.tar.xz": "2654b66759e7ea6537c2e11e98f549df519fc65e4ffc04910574f16bbd03b9be",
    "aarch64-linux-aarch64-linux-musl-gcc-13.4.0-20260310.tar.xz": "fd43933228e5877412b2f7b0357fd3c258aab4870b6110a0377e98452fdedd41",
    "aarch64-linux-musl-gcc-lib-13.4.0-20260310.tar.xz": "bcb7446f2ff6d2ad26ebd93936cb5276eaad7f3ff76e0035aa0427bce03f72bd",
    "aarch64-linux-aarch64-linux-gnu-gcc-14.2.0-20260310.tar.xz": "c33cf47641a22e09724fb294352da485d88b4e7866d6cdc28d96b59e352b4396",
    "aarch64-linux-gnu-gcc-lib-14.2.0-20260310.tar.xz": "1213c4e6460fee1f558f921bcec5c0c8c20e36c2b6f0285a1b03f907f028a9f1",
    "aarch64-linux-aarch64-linux-musl-gcc-14.2.0-20260310.tar.xz": "0fad9008e4ec8aae11bdfc37b5cc3136e1b2bf5ff5b60fae6b06c89fe7037b5d",
    "aarch64-linux-musl-gcc-lib-14.2.0-20260310.tar.xz": "6ac7851581c8dbaf55175604b900a4ea143bdfdb23eeb8e1e70efdac609539dd",
    "aarch64-linux-aarch64-linux-gnu-gcc-15.2.0-20260228.tar.xz": "56103e50a905906ea78b0a4e291b4c3fb92b2a182cc3b185b55229d3323b219a",
    "aarch64-linux-gnu-gcc-lib-15.2.0-20260228.tar.xz": "93951d47eb9aa4d31e0167ab015d98b688d919659577573fae636ddb3c806559",
    "aarch64-linux-aarch64-linux-musl-gcc-15.2.0-20260228.tar.xz": "8954b1a7a08a088fa692cf8b44e2522b33f45011e5712bb0123871a85c6cd4f7",
    "aarch64-linux-musl-gcc-lib-15.2.0-20260228.tar.xz": "194dfbc9737df0262ab216c65ebb528d0686fe7a0f463a59e3e370f0598d923b",
}
