SUPPORTED_CXX_STD_LIBS = [
    "libc++",
    "libstdc++",
]

def get_config_from_env_vars(rctx):
    cxx_std_lib_var = "{}_cxx_std_lib".format(rctx.attr.toolchain_name)
    cxx_std_lib = rctx.getenv(cxx_std_lib_var)
    if cxx_std_lib == None:
        cxx_std_lib = "libstdc++"

    if cxx_std_lib not in SUPPORTED_CXX_STD_LIBS:
        fail("Unrecognized cxx_std_lib: {}={}".format(cxx_std_lib_var, cxx_std_lib))

    return {
        "cxx_std_lib": cxx_std_lib,
    }
