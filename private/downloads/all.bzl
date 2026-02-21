"""Functions for downloading all toolchain binaries."""

load(":binutils.bzl", "download_binutils")
load(":gcc.bzl", "download_gcc")
load(":glibc.bzl", "download_glibc")
load(":linux_headers.bzl", "download_linux_headers")

visibility("//private/...")

def download_all(rctx, config):
    """Download and extract all toolchain binaries and sysroot.

    Args:
      rctx: The repository context.
      config: The configuration dictionary.
    """
    download_gcc(rctx, config)
    download_binutils(rctx, config)
    download_glibc(rctx, config)
    download_linux_headers(rctx, config)
