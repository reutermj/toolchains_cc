FROM ubuntu:latest

# ===========
# || Setup ||
# ===========
ENV SCRIPTS_DIR="/tmp/scripts"
ENV UTILS_DIR="/tmp/scripts"

COPY .github/workflows/utils/initialize_user $UTILS_DIR/initialize_user
RUN $UTILS_DIR/initialize_user

USER builder
WORKDIR /home/builder

COPY .github/workflows/build_libclang/environment $SCRIPTS_DIR/environment
COPY .github/workflows/utils/download_tarball $UTILS_DIR/download_tarball

# ======================
# || Build libclang  ||
# ======================
COPY .github/workflows/build_libclang/step-1_install_dependencies $SCRIPTS_DIR/step-1_install_dependencies
RUN $SCRIPTS_DIR/step-1_install_dependencies

COPY .github/workflows/utils/install_gh_cli $UTILS_DIR/install_gh_cli
RUN $UTILS_DIR/install_gh_cli

ARG GH_TOKEN
ARG ZLIB_VERSION=1.3.1
COPY .github/workflows/build_libclang/step-2.1_download_zlib_source $SCRIPTS_DIR/step-2.1_download_zlib_source
RUN $SCRIPTS_DIR/step-2.1_download_zlib_source

ARG LLVM_VERSION=21.1.1
COPY .github/workflows/build_libclang/step-2.2_download_llvm_source $SCRIPTS_DIR/step-2.2_download_llvm_source
RUN $SCRIPTS_DIR/step-2.2_download_llvm_source

ARG GCC_VERSION=15.2.0
ARG GLIBC_VERSION=2.28
COPY .github/workflows/build_libclang/step-2.3_install_gcc $SCRIPTS_DIR/step-2.3_install_gcc
RUN $SCRIPTS_DIR/step-2.3_install_gcc

ARG LINUX_VERSION=6.18
COPY .github/workflows/build_libclang/step-2.4_install_linux_headers $SCRIPTS_DIR/step-2.4_install_linux_headers
RUN $SCRIPTS_DIR/step-2.4_install_linux_headers

COPY .github/workflows/build_libclang/step-3_build_zlib $SCRIPTS_DIR/step-3_build_zlib
RUN $SCRIPTS_DIR/step-3_build_zlib

COPY .github/workflows/build_libclang/step-4_build_libclang $SCRIPTS_DIR/step-4_build_libclang
RUN $SCRIPTS_DIR/step-4_build_libclang

COPY .github/workflows/build_libclang/step-5_package_toolchain $SCRIPTS_DIR/step-5_package_toolchain
RUN $SCRIPTS_DIR/step-5_package_toolchain
