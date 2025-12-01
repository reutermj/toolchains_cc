FROM ubuntu:latest

# Build arguments for parameterizing binutils version and target
ARG BINUTILS_VERSION=2.43
ARG TARGET=x86_64-linux-gnu

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
COPY environment $SCRIPTS_DIR/environment

ENV BINUTILS_VERSION=${BINUTILS_VERSION}
ENV TARGET=${TARGET}

# ====================
# || Build binutils ||
# ====================
COPY step-1_install_dependencies $SCRIPTS_DIR/step-1_install_dependencies
RUN $SCRIPTS_DIR/step-1_install_dependencies

COPY step-2_download_sources $SCRIPTS_DIR/step-2_download_sources
RUN $SCRIPTS_DIR/step-2_download_sources

COPY step-3_build_zlib $SCRIPTS_DIR/step-3_build_zlib
RUN $SCRIPTS_DIR/step-3_build_zlib

COPY step-4_build_binutils $SCRIPTS_DIR/step-4_build_binutils
RUN $SCRIPTS_DIR/step-4_build_binutils

COPY step-5_package_binutils $SCRIPTS_DIR/step-5_package_binutils
RUN $SCRIPTS_DIR/step-5_package_binutils

# The artifact will be in /tmp/artifacts/
# You can extract it with: docker cp <container>:/tmp/artifacts/ .
