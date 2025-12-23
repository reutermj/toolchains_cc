FROM ubuntu:latest

# This docker file allows for testing the build_gcc.yml actions workload locally.
# args:
#   * GCC_VERSION: version of gcc to use. ct-ng only supports building the latest minor revision of the specific major revision.
#                  the supported values will differ between different commits of ct-ng.
#   * LIBC: build a glibc or musl based toolchain
#   * LIBC_VERSION: version of the specified libc to use. based on the supported versions ct-ng enables building.
#   * GITHUB_TOKEN: the token used to upload artifacts to the release. will skip the upload if not provided

# =================
# || Create User ||
# =================
# ct-ng cant build as root; it needs to run as a user.
# as well, github actions need sudo to install ct-ng after building and to do apt install
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y sudo gh

RUN useradd -m -s /bin/bash builder && \
    usermod -aG sudo builder
RUN echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER builder
WORKDIR /tmp/work

# =======================
# || Environment Setup ||
# =======================
ENV SCRIPTS_DIR="/tmp/scripts"
COPY .github/workflows/build_gcc_ct-ng/environment $SCRIPTS_DIR/environment

# =====================
# || Build Toolchain ||
# =====================
COPY .github/workflows/build_gcc_ct-ng/step-1_install_dependencies $SCRIPTS_DIR/step-1_install_dependencies
RUN $SCRIPTS_DIR/step-1_install_dependencies

COPY .github/workflows/build_gcc_ct-ng/step-2_build_crosstool_ng $SCRIPTS_DIR/step-2_build_crosstool_ng
RUN $SCRIPTS_DIR/step-2_build_crosstool_ng

ARG GCC_VERSION=15
ARG LIBC=gnu
ARG LIBC_VERSION=2.34
COPY .github/workflows/build_gcc_ct-ng/step-3_configure_toolchain $SCRIPTS_DIR/step-3_configure_toolchain
RUN $SCRIPTS_DIR/step-3_configure_toolchain

# =============================
# || Extracted Build Scripts ||
# =============================
COPY step-04_download_sources $SCRIPTS_DIR/step-04_download_sources
RUN $SCRIPTS_DIR/step-04_download_sources

COPY step-02_working-directory $SCRIPTS_DIR/step-02_working-directory
RUN $SCRIPTS_DIR/step-02_working-directory

COPY step-05_extract_sources $SCRIPTS_DIR/step-05_extract_sources
RUN $SCRIPTS_DIR/step-05_extract_sources

COPY step-06.1_build $SCRIPTS_DIR/step-06.1_build
RUN $SCRIPTS_DIR/step-06.1_build

COPY step-06.3_build $SCRIPTS_DIR/step-06.3_build
RUN $SCRIPTS_DIR/step-06.3_build

COPY step-06.4_build $SCRIPTS_DIR/step-06.4_build
RUN $SCRIPTS_DIR/step-06.4_build

COPY step-06.5_build $SCRIPTS_DIR/step-06.5_build
RUN $SCRIPTS_DIR/step-06.5_build

COPY step-06.6_build $SCRIPTS_DIR/step-06.6_build
RUN $SCRIPTS_DIR/step-06.6_build

COPY step-06.9_build $SCRIPTS_DIR/step-06.9_build
RUN $SCRIPTS_DIR/step-06.9_build

COPY step-06.10_build $SCRIPTS_DIR/step-06.10_build
RUN $SCRIPTS_DIR/step-06.10_build

COPY step-06.11_build $SCRIPTS_DIR/step-06.11_build
RUN $SCRIPTS_DIR/step-06.11_build

COPY step-06.12_build $SCRIPTS_DIR/step-06.12_build
RUN $SCRIPTS_DIR/step-06.12_build

COPY step-06.13_build $SCRIPTS_DIR/step-06.13_build
RUN $SCRIPTS_DIR/step-06.13_build
