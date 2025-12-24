FROM ubuntu:latest

# ================
# || Initialize ||
# ================
ENV SCRIPTS_DIR="/tmp/scripts"
ENV UTILS_DIR="/tmp/scripts"
ENV GCC_VERSION=15.2.0

COPY .github/workflows/utils/initialize_user $UTILS_DIR/initialize_user
RUN $UTILS_DIR/initialize_user

USER builder
WORKDIR /home/builder

COPY .github/workflows/build_gcc_musl/environment $SCRIPTS_DIR/environment
COPY .github/workflows/utils/download_tarball $UTILS_DIR/download_tarball

# =================
# || Build GCC   ||
# =================
COPY .github/workflows/build_gcc_musl/step-1_install_dependencies $SCRIPTS_DIR/step-1_install_dependencies
RUN $SCRIPTS_DIR/step-1_install_dependencies

COPY .github/workflows/utils/install_gh_cli $UTILS_DIR/install_gh_cli
RUN $UTILS_DIR/install_gh_cli

ARG GH_TOKEN
COPY .github/workflows/build_gcc_musl/step-2.1_download_binutils_source $SCRIPTS_DIR/step-2.1_download_binutils_source
RUN $SCRIPTS_DIR/step-2.1_download_binutils_source

COPY .github/workflows/build_gcc_musl/step-2.2_download_gcc_source $SCRIPTS_DIR/step-2.2_download_gcc_source
RUN $SCRIPTS_DIR/step-2.2_download_gcc_source

COPY .github/workflows/build_gcc_musl/step-2.3_download_gmp_source $SCRIPTS_DIR/step-2.3_download_gmp_source
RUN $SCRIPTS_DIR/step-2.3_download_gmp_source

COPY .github/workflows/build_gcc_musl/step-2.4_download_isl_source $SCRIPTS_DIR/step-2.4_download_isl_source
RUN $SCRIPTS_DIR/step-2.4_download_isl_source

COPY .github/workflows/build_gcc_musl/step-2.5_download_linux_source $SCRIPTS_DIR/step-2.5_download_linux_source
RUN $SCRIPTS_DIR/step-2.5_download_linux_source

COPY .github/workflows/build_gcc_musl/step-2.6_download_mpc_source $SCRIPTS_DIR/step-2.6_download_mpc_source
RUN $SCRIPTS_DIR/step-2.6_download_mpc_source

COPY .github/workflows/build_gcc_musl/step-2.7_download_mpfr_source $SCRIPTS_DIR/step-2.7_download_mpfr_source
RUN $SCRIPTS_DIR/step-2.7_download_mpfr_source

COPY .github/workflows/build_gcc_musl/step-2.8_download_musl_source $SCRIPTS_DIR/step-2.8_download_musl_source
RUN $SCRIPTS_DIR/step-2.8_download_musl_source

COPY .github/workflows/build_gcc_musl/step-2.9_download_zlib_source $SCRIPTS_DIR/step-2.9_download_zlib_source
RUN $SCRIPTS_DIR/step-2.9_download_zlib_source

COPY .github/workflows/build_gcc_musl/step-3.01_build_zlib $SCRIPTS_DIR/step-3.01_build_zlib
RUN $SCRIPTS_DIR/step-3.01_build_zlib

COPY .github/workflows/build_gcc_musl/step-3.02_build_gmp $SCRIPTS_DIR/step-3.02_build_gmp
RUN $SCRIPTS_DIR/step-3.02_build_gmp

COPY .github/workflows/build_gcc_musl/step-3.03_build_mpfr $SCRIPTS_DIR/step-3.03_build_mpfr
RUN $SCRIPTS_DIR/step-3.03_build_mpfr

COPY .github/workflows/build_gcc_musl/step-3.04_build_isl $SCRIPTS_DIR/step-3.04_build_isl
RUN $SCRIPTS_DIR/step-3.04_build_isl

COPY .github/workflows/build_gcc_musl/step-3.05_build_mpc $SCRIPTS_DIR/step-3.05_build_mpc
RUN $SCRIPTS_DIR/step-3.05_build_mpc

COPY .github/workflows/build_gcc_musl/step-3.06_build_binutils $SCRIPTS_DIR/step-3.06_build_binutils
RUN $SCRIPTS_DIR/step-3.06_build_binutils

COPY .github/workflows/build_gcc_musl/step-3.07_install_linux_headers $SCRIPTS_DIR/step-3.07_install_linux_headers
RUN $SCRIPTS_DIR/step-3.07_install_linux_headers

COPY .github/workflows/build_gcc_musl/step-3.08_build_core_gcc $SCRIPTS_DIR/step-3.08_build_core_gcc
RUN $SCRIPTS_DIR/step-3.08_build_core_gcc

COPY .github/workflows/build_gcc_musl/step-3.09_build_musl $SCRIPTS_DIR/step-3.09_build_musl
RUN $SCRIPTS_DIR/step-3.09_build_musl

COPY .github/workflows/build_gcc_musl/step-3.10_build_final_gcc $SCRIPTS_DIR/step-3.10_build_final_gcc
RUN $SCRIPTS_DIR/step-3.10_build_final_gcc
