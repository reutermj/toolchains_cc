FROM ubuntu:latest

ARG COMPONENT=gcc
ARG VERSION=15.2.0

# =================
# || Create User ||
# =================
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y sudo gh

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

ENV COMPONENT=${COMPONENT}
ENV VERSION=${VERSION}

# ============================
# || Create Source Tarballs ||
# ============================
COPY step-1_install_dependencies $SCRIPTS_DIR/step-1_install_dependencies
RUN $SCRIPTS_DIR/step-1_install_dependencies

COPY step-2_download_source $SCRIPTS_DIR/step-2_download_source
RUN $SCRIPTS_DIR/step-2_download_source

COPY step-3_create_tarball $SCRIPTS_DIR/step-3_create_tarball
RUN $SCRIPTS_DIR/step-3_create_tarball
