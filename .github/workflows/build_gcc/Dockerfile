FROM ubuntu:latest

ARG GCC_VERSION=15.2.0

# =================
# || Create User ||
# =================
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y sudo

RUN useradd -m -s /bin/bash builder && \
    usermod -aG sudo builder
RUN echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER builder
WORKDIR /home/builder

# =================
# || Environment ||
# =================
ENV SCRIPTS_DIR="/tmp/scripts"
ENV UTILS_DIR="/tmp/scripts"
ENV GCC_VERSION=${GCC_VERSION}

COPY .github/workflows/build_gcc/environment $SCRIPTS_DIR/environment
COPY .github/workflows/utils/download_tarball $UTILS_DIR/download_tarball

# =================
# || Build GCC   ||
# =================
COPY .github/workflows/build_gcc/step-01_install_dependencies $SCRIPTS_DIR/step-01_install_dependencies
RUN $SCRIPTS_DIR/step-01_install_dependencies

# Install newer GitHub CLI for attestation support (requires v2.47.0+)
# Ubuntu package version is too old, so install from GitHub releases
# We can assume the actions runner has a good enough version of gh so we only need it in the dockerfile
ARG GH_VERSION="2.63.2"
RUN wget "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" && \
    tar -xzf "gh_${GH_VERSION}_linux_amd64.tar.gz" && \
    sudo install "gh_${GH_VERSION}_linux_amd64/bin/gh" /usr/local/bin/gh

ARG GH_TOKEN
COPY .github/workflows/build_gcc/step-2.1_download_gmp_source $SCRIPTS_DIR/step-2.1_download_gmp_source
RUN $SCRIPTS_DIR/step-2.1_download_gmp_source

COPY .github/workflows/build_gcc/step-2.2_download_mpfr_source $SCRIPTS_DIR/step-2.2_download_mpfr_source
RUN $SCRIPTS_DIR/step-2.2_download_mpfr_source

COPY .github/workflows/build_gcc/step-2.3_download_isl_source $SCRIPTS_DIR/step-2.3_download_isl_source
RUN $SCRIPTS_DIR/step-2.3_download_isl_source

COPY .github/workflows/build_gcc/step-2.4_download_mpc_source $SCRIPTS_DIR/step-2.4_download_mpc_source
RUN $SCRIPTS_DIR/step-2.4_download_mpc_source

COPY .github/workflows/build_gcc/step-2.5_download_gcc_source $SCRIPTS_DIR/step-2.5_download_gcc_source
RUN $SCRIPTS_DIR/step-2.5_download_gcc_source

COPY .github/workflows/build_gcc/step-2.6_download_linux_source $SCRIPTS_DIR/step-2.6_download_linux_source
RUN $SCRIPTS_DIR/step-2.6_download_linux_source

COPY .github/workflows/build_gcc/step-3.1_install_linux_headers $SCRIPTS_DIR/step-3.1_install_linux_headers
RUN $SCRIPTS_DIR/step-3.1_install_linux_headers

COPY .github/workflows/build_gcc/step-3.2_install_glibc $SCRIPTS_DIR/step-3.2_install_glibc
RUN $SCRIPTS_DIR/step-3.2_install_glibc

COPY .github/workflows/build_gcc/step-4.1_build_gmp $SCRIPTS_DIR/step-4.1_build_gmp
RUN $SCRIPTS_DIR/step-4.1_build_gmp

COPY .github/workflows/build_gcc/step-4.2_build_isl $SCRIPTS_DIR/step-4.2_build_isl
RUN $SCRIPTS_DIR/step-4.2_build_isl

COPY .github/workflows/build_gcc/step-4.3_build_mpfr $SCRIPTS_DIR/step-4.3_build_mpfr
RUN $SCRIPTS_DIR/step-4.3_build_mpfr

COPY .github/workflows/build_gcc/step-4.4_build_mpc $SCRIPTS_DIR/step-4.4_build_mpc
RUN $SCRIPTS_DIR/step-4.4_build_mpc

COPY .github/workflows/build_gcc/step-4.5_build_gcc $SCRIPTS_DIR/step-4.5_build_gcc
RUN $SCRIPTS_DIR/step-4.5_build_gcc

COPY .github/workflows/build_gcc/step-5_package_toolchain $SCRIPTS_DIR/step-5_package_toolchain
RUN $SCRIPTS_DIR/step-5_package_toolchain
