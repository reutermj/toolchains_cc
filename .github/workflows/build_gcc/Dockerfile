FROM ubuntu:latest

# Build arguments for parameterizing GCC and glibc versions
ARG GCC_VERSION=15.2.0
ARG GLIBC_VERSION=2.28

# NOTE: This Dockerfile requires GH_TOKEN to download prebuilt binutils and glibc artifacts.
# Build with: docker build --build-arg GH_TOKEN=$GH_TOKEN ...

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
ARG GH_TOKEN
ENV GH_TOKEN=${GH_TOKEN}
ENV SCRIPTS_DIR="/tmp/scripts"
COPY environment $SCRIPTS_DIR/environment

ENV GCC_VERSION=${GCC_VERSION}
ENV GLIBC_VERSION=${GLIBC_VERSION}

# =====================
# || Build Toolchain ||
# =====================
COPY step-01_install_dependencies $SCRIPTS_DIR/step-01_install_dependencies
RUN $SCRIPTS_DIR/step-01_install_dependencies

COPY step-02_download_prebuilt_artifacts $SCRIPTS_DIR/step-02_download_prebuilt_artifacts
RUN $SCRIPTS_DIR/step-02_download_prebuilt_artifacts

COPY step-03_download_source $SCRIPTS_DIR/step-03_download_source
RUN $SCRIPTS_DIR/step-03_download_source

COPY step-04_build_gmp $SCRIPTS_DIR/step-04_build_gmp
RUN $SCRIPTS_DIR/step-04_build_gmp

COPY step-05_build_mpfr $SCRIPTS_DIR/step-05_build_mpfr
RUN $SCRIPTS_DIR/step-05_build_mpfr

COPY step-06_build_isl $SCRIPTS_DIR/step-06_build_isl
RUN $SCRIPTS_DIR/step-06_build_isl

COPY step-07_build_mpc $SCRIPTS_DIR/step-07_build_mpc
RUN $SCRIPTS_DIR/step-07_build_mpc

COPY step-08_build_gcc $SCRIPTS_DIR/step-08_build_gcc
RUN $SCRIPTS_DIR/step-08_build_gcc

COPY step-09_package_artifacts $SCRIPTS_DIR/step-09_package_artifacts
RUN $SCRIPTS_DIR/step-09_package_artifacts

ARG GITHUB_TOKEN
COPY step-10_upload_release $SCRIPTS_DIR/step-10_upload_release
RUN $SCRIPTS_DIR/step-10_upload_release

# The artifact will be in /tmp/artifacts/
# You can extract it with: docker cp <container>:/tmp/artifacts/ .
