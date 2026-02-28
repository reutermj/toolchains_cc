"""Shared constants for downloading toolchain binaries."""

visibility("//private/...")

DOWNLOAD_BASE_URL = "https://github.com/reutermj/toolchains_cc/releases/download/binaries"

def get_host(config):
    """Derive the host platform prefix from the target triple.

    Only native builds are supported (host arch == target arch), so the host
    is derived directly from the target triple.

    Args:
        config: The configuration dictionary containing "target".

    Returns:
        The host platform prefix (e.g., "x86_64-linux", "aarch64-linux").
    """
    target = config["target"]
    arch = target.split("-")[0]
    return "{}-linux".format(arch)
