load("@toolchains_cc_platform_defaults//:platform_constants.bzl", "CXX_STD_LIB")

package(default_visibility = ["//visibility:public"])

constraint_setting(
    name = "c++",
    default_constraint_value = CXX_STD_LIB,
)

constraint_value(
    name = "libc++",
    constraint_setting = ":c++",
)

constraint_value(
    name = "libstdc++",
    constraint_setting = ":c++",
)
