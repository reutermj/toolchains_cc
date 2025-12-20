FROM ubuntu:latest

ARG BINUTILS_VERSION=2.43

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
COPY .github/workflows/build_binutils/environment $SCRIPTS_DIR/environment
COPY .github/workflows/utils/source_download $UTILS_DIR/source_download

# ====================
# || Build binutils ||
# ====================
COPY .github/workflows/build_binutils/step-1_install_dependencies $SCRIPTS_DIR/step-1_install_dependencies
RUN $SCRIPTS_DIR/step-1_install_dependencies

# Install newer GitHub CLI for attestation support (requires v2.47.0+)
# Ubuntu package version is too old, so install from GitHub releases
# We can assume the actions runner has a good enough version of gh so we only need it in the dockerfile
ARG GH_VERSION="2.63.2"
RUN wget "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" && \
    tar -xzf "gh_${GH_VERSION}_linux_amd64.tar.gz" && \
    sudo install "gh_${GH_VERSION}_linux_amd64/bin/gh" /usr/local/bin/gh

ARG GH_TOKEN
COPY .github/workflows/build_binutils/step-2.1_download_binutils_source $SCRIPTS_DIR/step-2.1_download_binutils_source
RUN $SCRIPTS_DIR/step-2.1_download_binutils_source

COPY .github/workflows/build_binutils/step-2.2_download_zlib_source $SCRIPTS_DIR/step-2.2_download_zlib_source
RUN $SCRIPTS_DIR/step-2.2_download_zlib_source

COPY .github/workflows/build_binutils/step-3.1_build_zlib $SCRIPTS_DIR/step-3.1_build_zlib
RUN $SCRIPTS_DIR/step-3.1_build_zlib

COPY .github/workflows/build_binutils/step-3.2_build_binutils $SCRIPTS_DIR/step-3.2_build_binutils
RUN $SCRIPTS_DIR/step-3.2_build_binutils

COPY .github/workflows/build_binutils/step-4_package_binutils $SCRIPTS_DIR/step-4_package_binutils
RUN $SCRIPTS_DIR/step-4_package_binutils
