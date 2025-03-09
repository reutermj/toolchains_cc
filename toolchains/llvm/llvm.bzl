load("@bazel_skylib//lib:dicts.bzl", "dicts")
load(":19.1.7.bzl", "LLVM_19_1_7")

package(default_visibility = ["//:__subpackages__"])

LLVM = dicts.add(
    LLVM_19_1_7,
)
