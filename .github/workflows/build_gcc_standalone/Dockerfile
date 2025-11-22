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

# =====================
# || Build Toolchain ||
# =====================
COPY step-01_install_dependencies $SCRIPTS_DIR/step-01_install_dependencies
RUN $SCRIPTS_DIR/step-01_install_dependencies

COPY environment $SCRIPTS_DIR/environment

COPY step-02_download_source $SCRIPTS_DIR/step-02_download_source
RUN $SCRIPTS_DIR/step-02_download_source

COPY step-03_build_ncurses $SCRIPTS_DIR/step-03_build_ncurses
RUN $SCRIPTS_DIR/step-03_build_ncurses

COPY step-04_build_zlib $SCRIPTS_DIR/step-04_build_zlib
RUN $SCRIPTS_DIR/step-04_build_zlib

COPY step-05_build_zstd $SCRIPTS_DIR/step-05_build_zstd
RUN $SCRIPTS_DIR/step-05_build_zstd

COPY step-06_build_gmp $SCRIPTS_DIR/step-06_build_gmp
RUN $SCRIPTS_DIR/step-06_build_gmp

COPY step-07_build_mpfr $SCRIPTS_DIR/step-07_build_mpfr
RUN $SCRIPTS_DIR/step-07_build_mpfr

COPY step-08_build_isl $SCRIPTS_DIR/step-08_build_isl
RUN $SCRIPTS_DIR/step-08_build_isl

COPY step-09_build_mpc $SCRIPTS_DIR/step-09_build_mpc
RUN $SCRIPTS_DIR/step-09_build_mpc

COPY step-10_build_expat $SCRIPTS_DIR/step-10_build_expat
RUN $SCRIPTS_DIR/step-10_build_expat

COPY step-11_build_binutils $SCRIPTS_DIR/step-11_build_binutils
RUN $SCRIPTS_DIR/step-11_build_binutils

COPY step-12_install_linux_headers $SCRIPTS_DIR/step-12_install_linux_headers
RUN $SCRIPTS_DIR/step-12_install_linux_headers

COPY step-13_bootstrap_gcc $SCRIPTS_DIR/step-13_bootstrap_gcc
RUN $SCRIPTS_DIR/step-13_bootstrap_gcc

COPY step-14_build_glibc $SCRIPTS_DIR/step-14_build_glibc
RUN $SCRIPTS_DIR/step-14_build_glibc

COPY step-15_build_gcc $SCRIPTS_DIR/step-15_build_gcc
RUN $SCRIPTS_DIR/step-15_build_gcc

COPY step-16_package_toolchain $SCRIPTS_DIR/step-16_package_toolchain
RUN $SCRIPTS_DIR/step-16_package_toolchain

ARG GITHUB_TOKEN
COPY step-17_upload_release $SCRIPTS_DIR/step-17_upload_release
RUN $SCRIPTS_DIR/step-17_upload_release
