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
    "x86_64-linux-gnu-glibc-2.31": "20260311",
    "aarch64-linux-gnu-glibc-2.31": "20260311",
    "x86_64-linux-gnu-glibc-2.32": "20260311",
    "aarch64-linux-gnu-glibc-2.32": "20260311",
    "x86_64-linux-gnu-glibc-2.33": "20260311",
    "aarch64-linux-gnu-glibc-2.33": "20260311",
    "x86_64-linux-gnu-glibc-2.34": "20260311",
    "aarch64-linux-gnu-glibc-2.34": "20260311",
    "x86_64-linux-gnu-glibc-2.35": "20260311",
    "aarch64-linux-gnu-glibc-2.35": "20260311",
    "x86_64-linux-gnu-glibc-2.36": "20260311",
    "aarch64-linux-gnu-glibc-2.36": "20260311",
    "x86_64-linux-gnu-glibc-2.37": "20260311",
    "aarch64-linux-gnu-glibc-2.37": "20260311",
    "x86_64-linux-gnu-glibc-2.38": "20260311",
    "aarch64-linux-gnu-glibc-2.38": "20260311",
    "x86_64-linux-gnu-glibc-2.39": "20260311",
    "aarch64-linux-gnu-glibc-2.39": "20260311",
}

TARBALL_TO_SHA256 = {
    "x86_64-linux-gnu-glibc-2.28-20260218.tar.xz": "c808d0145434c9fbb273662712c212b99489489396a09b50faa84212f070a9e7",
    "aarch64-linux-gnu-glibc-2.28-20260228.tar.xz": "28a46420f38d2f975544f24ee70cedd45c698abed32e567eaa60db0eeb4364b0",
    "x86_64-linux-gnu-glibc-2.29-20260311.tar.xz": "04b3e173d1f1f9bd7cc18ebe65f37bcda934b4c8f85ee24f7cf8de1f7ef96ab4",
    "aarch64-linux-gnu-glibc-2.29-20260311.tar.xz": "af89007391be9ad68be00445d2b0de50d0e0ab422435cc27800307b3ce26787d",
    "x86_64-linux-gnu-glibc-2.30-20260311.tar.xz": "66fa79ae6974f1c9b8048501830473c55ebf05ae8510a671aee232351a496ce1",
    "aarch64-linux-gnu-glibc-2.30-20260311.tar.xz": "2d4d2f27559dec5f95415e3dd7bb5e4ee3ddb36516f1b969214cadd66a365cf4",
    "x86_64-linux-gnu-glibc-2.31-20260311.tar.xz": "2ab1a85526596c227bedd2e71c5c94b075ec61c91fdb9d5e68b3eb1dbfd0b01c",
    "aarch64-linux-gnu-glibc-2.31-20260311.tar.xz": "48cc98bb6cf2f0a9f1d3aace77266bdcaa30921df84fe275ee3c09a7c8b46a4d",
    "x86_64-linux-gnu-glibc-2.32-20260311.tar.xz": "b80c41adcc03f90777d2cc51ec648f759c203fc9eddf25cbf1c7107f3af0e53e",
    "aarch64-linux-gnu-glibc-2.32-20260311.tar.xz": "8ebf4ec3826701c3cb744dd2ce11b953b3a0890b7d71c0c1fc1fca1f3b256f2b",
    "x86_64-linux-gnu-glibc-2.33-20260311.tar.xz": "4662c98f122babd83e5f234e114abf7298f823818bf97fe692f235520730b8d4",
    "aarch64-linux-gnu-glibc-2.33-20260311.tar.xz": "6c2715a1c0a24cf20a90a04570219cce4efb229baa0edef5b61fe9353a450020",
    "x86_64-linux-gnu-glibc-2.34-20260311.tar.xz": "0d83696a6460a1cd2946de2fa767a373177d9d384639f275ecc8aa976cd896ad",
    "aarch64-linux-gnu-glibc-2.34-20260311.tar.xz": "98ba5f83e9ebe94c1dbcecc76ae0d6216189ca27b18fa81ea12c5eb81ba12e3e",
    "x86_64-linux-gnu-glibc-2.35-20260311.tar.xz": "5d2eeabeebe89514ff24cb6c5a5fb03a3952a85574128478f4d4048825e1266d",
    "aarch64-linux-gnu-glibc-2.35-20260311.tar.xz": "470c23e0aacc8c94b26cf9d391423eacc097bd6be6c5ff95472fbc6b02d1218b",
    "x86_64-linux-gnu-glibc-2.36-20260311.tar.xz": "f9f3844f48a866a26ac507815babd06289a00d3f18b3b89cf3bae7666642ca97",
    "aarch64-linux-gnu-glibc-2.36-20260311.tar.xz": "1ba95aab4d52f35bd83cd2fbc9c09fed215b8ad9430e2669d6553d2c69865e80",
    "x86_64-linux-gnu-glibc-2.37-20260311.tar.xz": "51da0696f0d8953d1b1490b8c6a22a6390c0ae7a8513a31c1541724925cd961d",
    "aarch64-linux-gnu-glibc-2.37-20260311.tar.xz": "437025c3b90f7637aaa82b3879c866e2ac256d4df7d56f69fca53c3cc55270f5",
    "x86_64-linux-gnu-glibc-2.38-20260311.tar.xz": "4d754d0efce5bc1950b757a536138674c53b482630b53ad4547e492a18d38870",
    "aarch64-linux-gnu-glibc-2.38-20260311.tar.xz": "9916003f086f70305a827e877bceff31fff7d50d737e8b3297b687c329070e4e",
    "x86_64-linux-gnu-glibc-2.39-20260311.tar.xz": "6cdd92f15cb293aeb5e4f41cecab567119400daf4e512a8216c0b066c653dfb8",
    "aarch64-linux-gnu-glibc-2.39-20260311.tar.xz": "bad7a4a22d13fb70076f72642f838b71e6cbfad53f5e5e77dcca74924d52c45b",
}
