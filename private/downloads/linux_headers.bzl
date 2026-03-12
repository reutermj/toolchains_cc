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
    "x86_64-linux-headers-6.0": "20260312",
    "aarch64-linux-headers-6.0": "20260312",
    "x86_64-linux-headers-6.1": "20260312",
    "aarch64-linux-headers-6.1": "20260312",
    "x86_64-linux-headers-6.2": "20260312",
    "aarch64-linux-headers-6.2": "20260312",
    "x86_64-linux-headers-6.3": "20260312",
    "aarch64-linux-headers-6.3": "20260312",
    "x86_64-linux-headers-6.4": "20260312",
    "aarch64-linux-headers-6.4": "20260312",
    "x86_64-linux-headers-6.5": "20260312",
    "aarch64-linux-headers-6.5": "20260312",
    "x86_64-linux-headers-6.6": "20260312",
    "aarch64-linux-headers-6.6": "20260312",
    "x86_64-linux-headers-6.7": "20260312",
    "aarch64-linux-headers-6.7": "20260312",
    "x86_64-linux-headers-6.8": "20260312",
    "aarch64-linux-headers-6.8": "20260312",
    "x86_64-linux-headers-6.9": "20260312",
    "aarch64-linux-headers-6.9": "20260312",
    "x86_64-linux-headers-6.10": "20260312",
    "aarch64-linux-headers-6.10": "20260312",
    "x86_64-linux-headers-6.11": "20260312",
    "aarch64-linux-headers-6.11": "20260312",
    "x86_64-linux-headers-6.12": "20260312",
    "aarch64-linux-headers-6.12": "20260312",
    "x86_64-linux-headers-6.13": "20260312",
    "aarch64-linux-headers-6.13": "20260312",
    "x86_64-linux-headers-6.14": "20260312",
    "aarch64-linux-headers-6.14": "20260312",
    "x86_64-linux-headers-6.15": "20260312",
    "aarch64-linux-headers-6.15": "20260312",
    "x86_64-linux-headers-6.16": "20260312",
    "aarch64-linux-headers-6.16": "20260312",
    "x86_64-linux-headers-6.17": "20260312",
    "aarch64-linux-headers-6.17": "20260312",
    "x86_64-linux-headers-6.18": "20260217",
    "aarch64-linux-headers-6.18": "20260228",
}

TARBALL_TO_SHA256 = {
    "x86_64-linux-headers-6.0-20260312.tar.xz": "c71a06eea2b32e7058cfac09fd2b0f17b1842d3fdf5150ecdd522665a5c05ac8",
    "aarch64-linux-headers-6.0-20260312.tar.xz": "03702a024e235a8cbbf6db477f1cabdcd31f3cf0680a293da3a4489af2e70a72",
    "x86_64-linux-headers-6.1-20260312.tar.xz": "0400e26d7c696ebb7761c17ca79f6d043c791ae60632bc456e139b0ac1cd2b66",
    "aarch64-linux-headers-6.1-20260312.tar.xz": "b5b96add6d77338b2e041ddd1e52403c0a7486be203b30ee5f46d13c7d68d795",
    "x86_64-linux-headers-6.2-20260312.tar.xz": "6158e54f27237eff03625aa535fcb8ba71fb5fc7a83649dd3779bfaa6852199b",
    "aarch64-linux-headers-6.2-20260312.tar.xz": "920328015c470189db3b5db2d4fd91b5dfd9291bb3b82b250e38582e3d8c16c0",
    "x86_64-linux-headers-6.3-20260312.tar.xz": "97f002ae8e6db3cb4f98fc25e37ae7ca6f2064d4beab9193ecf3f57c6c27249b",
    "aarch64-linux-headers-6.3-20260312.tar.xz": "d63ae2f999b019d398e415159e724491970d1eeb71c73063945ef9ab087da1c3",
    "x86_64-linux-headers-6.4-20260312.tar.xz": "11bab634b2a2c60f64001e837b34035570fe30f2a0afe9b80de28b3a034ff7ac",
    "aarch64-linux-headers-6.4-20260312.tar.xz": "463b5a4ba54578d96cf726225dad751c0de34f216ec3ebde481d16ecd30af1f8",
    "x86_64-linux-headers-6.5-20260312.tar.xz": "5940c8086a560d4facbffd82e225b08cf8268cfc3530ed4cdb869d2cfc3a35dd",
    "aarch64-linux-headers-6.5-20260312.tar.xz": "dc06b22dc2138e2e772a188579def509317dc95b2e1b643ae187714d3832a486",
    "x86_64-linux-headers-6.6-20260312.tar.xz": "9df334e3b1678b5c818a547694a0a89e861ddbe1f95012d41f1b8e12a395467a",
    "aarch64-linux-headers-6.6-20260312.tar.xz": "3de130de93f54757330258ca736716c1e13c50e14704f7f4e47a1af99efcc978",
    "x86_64-linux-headers-6.7-20260312.tar.xz": "bae1bb469547666d1004e2dc4d6d00b3e42bd74b6923fd8f2d56061e01d67e58",
    "aarch64-linux-headers-6.7-20260312.tar.xz": "684ac791a5050cd17edf7da862ee6590497dd6a40a96caba1db4096729fe1c11",
    "x86_64-linux-headers-6.8-20260312.tar.xz": "1a4cf4c8da851c2057238ec91d6b4a8d455bc282abc95e0b4584bc8e242ff558",
    "aarch64-linux-headers-6.8-20260312.tar.xz": "9926e87821fe8ba48ff38e4112aca931fe0f948e13fdaa7e743d101d918d13fa",
    "x86_64-linux-headers-6.9-20260312.tar.xz": "dffc7d8ef8673279950e196ccdd04e9b97088d73666db8bc5c61bc61045c75c6",
    "aarch64-linux-headers-6.9-20260312.tar.xz": "6581cbc19b7a91a526f28b9c9b5d16420beb59ec17f61c8b3c27c534778bd51f",
    "x86_64-linux-headers-6.10-20260312.tar.xz": "c923cb5f00209cbfb6f8481d2e26afb542126bafb15605e031fdac16c5d4a5bf",
    "aarch64-linux-headers-6.10-20260312.tar.xz": "14dc7cf3af1b19f3f931ccd77190af18bebec97814e610ad058913834c2bf7d9",
    "x86_64-linux-headers-6.11-20260312.tar.xz": "4d26e75348d5bcbbd6da43a296506e6565fd892c6ef8c026cb51c1165f1d079a",
    "aarch64-linux-headers-6.11-20260312.tar.xz": "f54f7adb080a701729943a944aa4ab92f013aef8475d01bbe29222ae5efd06d7",
    "x86_64-linux-headers-6.12-20260312.tar.xz": "631caface55d477d0ddf7a9153506174313f121de0694f1806709c911bb46055",
    "aarch64-linux-headers-6.12-20260312.tar.xz": "ef5a7c2c6ad1f9d37eb8df9f0be066889bfcd8b58f87da0ee0e9e14338d365e9",
    "x86_64-linux-headers-6.13-20260312.tar.xz": "5e75a9430821f89a47eb6d538f378693f17ca1c20e4a18d25faeb4ff9ca0996c",
    "aarch64-linux-headers-6.13-20260312.tar.xz": "1f71cdcd24cb06a81a9055478ea677f8ce9a93f372eee415339639aac6e04f33",
    "x86_64-linux-headers-6.14-20260312.tar.xz": "f4b9d5c2234a542adc165c480888780d7fddbf95112a2054bb18696d11cea132",
    "aarch64-linux-headers-6.14-20260312.tar.xz": "36cd863a3f2b4fbbe538e2b7d9622bc0c5538f58603f591ed2aad3b628e8eddb",
    "x86_64-linux-headers-6.15-20260312.tar.xz": "4cb578eb4c63004233ef29a73911730ff5160d5bcd9deeb737a457f1670141a3",
    "aarch64-linux-headers-6.15-20260312.tar.xz": "3f01d9c43b37ebba3f7d2ea7330b01e980a6002641fcc4e4ea12932ac2244ad5",
    "x86_64-linux-headers-6.16-20260312.tar.xz": "8dab681fa4f3c2142725b44cd8c97abec6ff7a55b54c56b3af689c9d312f7728",
    "aarch64-linux-headers-6.16-20260312.tar.xz": "592f2589d6da8b284d824cfd00942488b83474acd2b3726e1d1b32204a16dd8e",
    "x86_64-linux-headers-6.17-20260312.tar.xz": "16ef4f46ca00c7fc901c82a3194a5858ced8ff12596125991724d9d971878553",
    "aarch64-linux-headers-6.17-20260312.tar.xz": "862a20b02812c11cccbb133566ab8ea260614f8ea5f14bb6f7203c5189704ae9",
    "x86_64-linux-headers-6.18-20260217.tar.xz": "34396267a578ef4b81b3951b826c236cf385f7f008bb20b348731ca3318b7c6f",
    "aarch64-linux-headers-6.18-20260228.tar.xz": "dafd326fe1df8fce64805b420666606f984a76087563e36c4ff69cb5e323751a",
}
