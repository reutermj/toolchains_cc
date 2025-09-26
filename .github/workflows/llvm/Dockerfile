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
RUN mkdir -p ${SCRIPTS_DIR}
COPY environment $SCRIPTS_DIR/environment

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

COPY step-4_package_toolchain $SCRIPTS_DIR/step-4_package_toolchain
RUN $SCRIPTS_DIR/step-4_package_toolchain

ARG GITHUB_TOKEN
COPY step-5_upload_release $SCRIPTS_DIR/step-5_upload_release
RUN $SCRIPTS_DIR/step-5_upload_release
