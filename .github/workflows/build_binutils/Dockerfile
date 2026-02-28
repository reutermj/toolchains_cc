FROM ubuntu:latest

# ===========
# || Setup ||
# ===========
ENV SCRIPTS_DIR="/tmp/scripts"
ENV UTILS_DIR="/tmp/scripts"
ENV PATCHES_DIR="/tmp/patches"

COPY .github/workflows/utils/initialize_user $UTILS_DIR/initialize_user
RUN $UTILS_DIR/initialize_user

USER builder
WORKDIR /home/builder

COPY .github/workflows/build_binutils/environment $SCRIPTS_DIR/environment
COPY .github/workflows/utils/download_tarball $UTILS_DIR/download_tarball

# ====================
# || Build binutils ||
# ====================
ARG TARGET=x86_64-linux-gnu

COPY .github/workflows/build_binutils/step-1_install_dependencies $SCRIPTS_DIR/step-1_install_dependencies
RUN $SCRIPTS_DIR/step-1_install_dependencies

COPY .github/workflows/utils/install_gh_cli $UTILS_DIR/install_gh_cli
RUN $UTILS_DIR/install_gh_cli

ARG GH_TOKEN
COPY .github/workflows/build_binutils/step-2.1_download_zlib_source $SCRIPTS_DIR/step-2.1_download_zlib_source
RUN $SCRIPTS_DIR/step-2.1_download_zlib_source

ARG BINUTILS_VERSION=2.43
COPY .github/workflows/build_binutils/step-2.2_download_binutils_source $SCRIPTS_DIR/step-2.2_download_binutils_source
RUN $SCRIPTS_DIR/step-2.2_download_binutils_source

COPY .github/workflows/build_binutils/patches $PATCHES_DIR
COPY .github/workflows/build_binutils/step-2.3_patch_binutils_source $SCRIPTS_DIR/step-2.3_patch_binutils_source
RUN $SCRIPTS_DIR/step-2.3_patch_binutils_source

COPY .github/workflows/build_binutils/step-3.1_build_zlib $SCRIPTS_DIR/step-3.1_build_zlib
RUN $SCRIPTS_DIR/step-3.1_build_zlib

COPY .github/workflows/build_binutils/step-3.2_build_binutils $SCRIPTS_DIR/step-3.2_build_binutils
RUN $SCRIPTS_DIR/step-3.2_build_binutils

COPY .github/workflows/build_binutils/step-4_package_binutils $SCRIPTS_DIR/step-4_package_binutils
RUN $SCRIPTS_DIR/step-4_package_binutils
