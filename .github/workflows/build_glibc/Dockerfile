FROM ubuntu:latest

ARG GLIBC_VERSION=2.28
ARG LINUX_VERSION=6.18

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
COPY .github/workflows/build_glibc/environment $SCRIPTS_DIR/environment
COPY .github/workflows/utils/download_tarball $UTILS_DIR/download_tarball

# =====================
# || Build glibc     ||
# =====================
COPY .github/workflows/build_glibc/step-1_install_dependencies $SCRIPTS_DIR/step-1_install_dependencies
RUN $SCRIPTS_DIR/step-1_install_dependencies

# Install newer GitHub CLI for attestation support (requires v2.47.0+)
# Ubuntu package version is too old, so install from GitHub releases
# We can assume the actions runner has a good enough version of gh so we only need it in the dockerfile
ARG GH_VERSION="2.63.2"
RUN wget "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" && \
    tar -xzf "gh_${GH_VERSION}_linux_amd64.tar.gz" && \
    sudo install "gh_${GH_VERSION}_linux_amd64/bin/gh" /usr/local/bin/gh

ARG GH_TOKEN
COPY .github/workflows/build_glibc/step-2.1_download_glibc_source $SCRIPTS_DIR/step-2.1_download_glibc_source
RUN $SCRIPTS_DIR/step-2.1_download_glibc_source

COPY .github/workflows/build_glibc/step-2.2_download_linux_source $SCRIPTS_DIR/step-2.2_download_linux_source
RUN $SCRIPTS_DIR/step-2.2_download_linux_source

COPY .github/workflows/build_glibc/step-3_install_linux_headers $SCRIPTS_DIR/step-3_install_linux_headers
RUN $SCRIPTS_DIR/step-3_install_linux_headers

COPY .github/workflows/build_glibc/step-4_build_glibc $SCRIPTS_DIR/step-4_build_glibc
RUN $SCRIPTS_DIR/step-4_build_glibc

COPY .github/workflows/build_glibc/step-5_package_glibc $SCRIPTS_DIR/step-5_package_glibc
RUN $SCRIPTS_DIR/step-5_package_glibc
