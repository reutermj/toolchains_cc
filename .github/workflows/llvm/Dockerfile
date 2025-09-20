# needs to be musl based to statically link
# when attempting glibc, it failed to link because clang uses some symbols that are only available when dynamic linking glibc
FROM ubuntu:latest

# =================
# || Create User ||
# =================
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y sudo gh

RUN useradd -m -s /bin/bash builder && \
    usermod -aG sudo builder
RUN echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER builder
WORKDIR /home/builder

# =======================
# || Environment Setup ||
# =======================
ENV SCRIPTS_DIR="/tmp/scripts"
ENV ZLIB_DIR="/tmp/zlib"
ENV LLVM_DIR="/tmp/llvm"
ENV GCC_DIR="/tmp/gcc"
ENV GCC_SYSROOT="${GCC_DIR}/x86_64-linux-musl/sysroot/"
ENV GCC_BINS="${GCC_DIR}/bin/"

RUN mkdir -p $SCRIPTS_DIR
RUN mkdir -p $ZLIB_DIR
RUN mkdir -p $LLVM_DIR
RUN mkdir -p $GCC_DIR

# =====================
# || Build Toolchain ||
# =====================
COPY step-1_install_dependencies $SCRIPTS_DIR/step-1_install_dependencies
RUN $SCRIPTS_DIR/step-1_install_dependencies

ARG ZLIB_VERSION=1.3.1
COPY step-2_build_zlib $SCRIPTS_DIR/step-2_build_zlib
RUN $SCRIPTS_DIR/step-2_build_zlib

ARG LLVM_VERSION=21.1.1
COPY step-3_build_llvm $SCRIPTS_DIR/step-3_build_llvm
RUN $SCRIPTS_DIR/step-3_build_llvm
