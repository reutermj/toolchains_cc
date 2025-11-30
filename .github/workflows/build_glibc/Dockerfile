FROM ubuntu:latest

# Build arguments for parameterizing glibc version and target
ARG GLIBC_VERSION=2.28
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

ENV GLIBC_VERSION=${GLIBC_VERSION}
ENV TARGET=${TARGET}

# =====================
# || Build glibc     ||
# =====================
COPY step-1_install_dependencies $SCRIPTS_DIR/step-1_install_dependencies
RUN $SCRIPTS_DIR/step-1_install_dependencies

COPY step-2_download_glibc_source $SCRIPTS_DIR/step-2_download_glibc_source
RUN $SCRIPTS_DIR/step-2_download_glibc_source

COPY step-3_download_linux_source $SCRIPTS_DIR/step-3_download_linux_source
RUN $SCRIPTS_DIR/step-3_download_linux_source

COPY step-4_install_linux_headers $SCRIPTS_DIR/step-4_install_linux_headers
RUN $SCRIPTS_DIR/step-4_install_linux_headers

COPY step-5_build_glibc $SCRIPTS_DIR/step-5_build_glibc
RUN $SCRIPTS_DIR/step-5_build_glibc

COPY step-6_package_glibc $SCRIPTS_DIR/step-6_package_glibc
RUN $SCRIPTS_DIR/step-6_package_glibc

# The artifact will be in /tmp/artifacts/
# You can extract it with: docker cp <container>:/tmp/artifacts/ .
