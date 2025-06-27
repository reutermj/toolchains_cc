load("@toolchains_cc_platform_defaults//:platform_constants.bzl", "VENDOR")

package(default_visibility = ["//visibility:public"])

constraint_setting(
    name = "vendor",
    default_constraint_value = VENDOR,
)

constraint_value(
    name = "unknown",
    constraint_setting = ":vendor",
)

constraint_value(
    name = "alpine",
    constraint_setting = ":vendor",
)
