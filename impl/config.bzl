"""Utilities for toolchain configurations."""

SUPPORTED_CXX_STD_LIBS = [
    "libstdc++",
]

SUPPORTED_TRIPLES = [
    "x86_64-linux-gnu",
    "x86_64-linux-musl",
]

def get_config_from_env_vars(rctx, toolchain_name = None):
    """Gets toolchain configurations from environment variables.

    Args:
        rctx: Repository context.
        toolchain_name: Name of the toolchain.

    Returns:
        A dictionary containing the configurations.
    """
    if toolchain_name == None:
        toolchain_name = rctx.attr.toolchain_name

    cxx_std_lib_var = "{}_cxx_std_lib".format(toolchain_name)
    cxx_std_lib = rctx.getenv(cxx_std_lib_var)
    if cxx_std_lib == None:
        cxx_std_lib = "libstdc++"
    if cxx_std_lib not in SUPPORTED_CXX_STD_LIBS:
        fail("Unrecognized cxx_std_lib: {}={}".format(cxx_std_lib_var, cxx_std_lib))

    triple_var = "{}_triple".format(toolchain_name)
    triple = rctx.getenv(triple_var)
    if triple == None:
        triple = "x86_64-linux-gnu"
    if triple not in SUPPORTED_TRIPLES:
        fail("Unrecognized triple: {}={}".format(triple_var, triple))

    triple_split = triple.split("-")
    arch = triple_split[0]
    os = triple_split[1]
    libc = triple_split[2]

    accept_winsdk_license_var = "{}_accept_winsdk_license".format(toolchain_name)
    accept_winsdk_license_str = rctx.getenv(accept_winsdk_license_var)
    if accept_winsdk_license_str == None:
        accept_winsdk_license = False
    else:
        accept_winsdk_license = accept_winsdk_license_str.lower() == "true"

    return {
        "accept_winsdk_license": accept_winsdk_license,
        "cxx_std_lib": cxx_std_lib,
        "arch": arch,
        "os": os,
        "libc": libc,
        "triple": triple,
    }

def repro_dump(rctx, config):
    # buildifier: disable=print
    print("""
--------============[[  Begin toolchains_cc repro dump  ]]============--------
For reproducing this build, use the following configurations in your .bazelrc:
common --repo_env={name}_triple={triple}
common --repo_env={name}_cxx_std_lib={cxx_std_lib}
--------============[[   End toolchains_cc repro dump   ]]============--------
""".format(
        name = rctx.attr.toolchain_name,
        cxx_std_lib = config["cxx_std_lib"],
        triple = config["triple"],
    ))
