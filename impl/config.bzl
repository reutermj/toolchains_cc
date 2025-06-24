load("@toolchains_cc_host_platform_constants//:platform_constants.bzl", "TRIPLE")

SUPPORTED_CXX_STD_LIBS = [
    "libc++",
    "libstdc++",
]

SUPPORTED_TRIPLES = [
    "x86_64-unknown-linux-gnu",
    "x86_64-alpine-linux-musl",
]

def get_config_from_env_vars(rctx):
    cxx_std_lib_var = "{}_cxx_std_lib".format(rctx.attr.toolchain_name)
    cxx_std_lib = rctx.getenv(cxx_std_lib_var)
    if cxx_std_lib == None:
        cxx_std_lib = "libstdc++"
    if cxx_std_lib not in SUPPORTED_CXX_STD_LIBS:
        fail("Unrecognized cxx_std_lib: {}={}".format(cxx_std_lib_var, cxx_std_lib))

    triple_var = "{}_triple".format(rctx.attr.toolchain_name)
    triple = rctx.getenv(triple_var)
    if triple == None:
        triple = TRIPLE
    if triple not in SUPPORTED_TRIPLES:
        fail("Unrecognized triple: {}={}".format(triple_var, triple))
    vendor = triple.split("-")[1]

    return {
        "cxx_std_lib": cxx_std_lib,
        "triple": triple,
        "vendor": vendor,
    }
