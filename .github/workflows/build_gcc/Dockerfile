FROM ubuntu:latest

# ===========
# || Setup ||
# ===========
ENV SCRIPTS_DIR="/tmp/scripts"
ENV UTILS_DIR="/tmp/scripts"

COPY .github/workflows/utils/initialize_user $UTILS_DIR/
RUN $UTILS_DIR/initialize_user

USER builder
WORKDIR /home/builder

COPY .github/workflows/build_gcc/environment $SCRIPTS_DIR/
COPY .github/workflows/utils/download_tarball $UTILS_DIR/

# ===============
# || Build GCC ||
# ===============
ARG TARGET=x86_64-linux-musl
COPY .github/workflows/build_gcc/step-01_install_dependencies $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-01_install_dependencies

COPY .github/workflows/utils/install_gh_cli $UTILS_DIR/
RUN $UTILS_DIR/install_gh_cli

ARG GH_TOKEN
COPY .github/workflows/build_gcc/step-2.1_download_gmp_source $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-2.1_download_gmp_source

COPY .github/workflows/build_gcc/step-2.2_download_mpfr_source $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-2.2_download_mpfr_source

COPY .github/workflows/build_gcc/step-2.3_download_isl_source $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-2.3_download_isl_source

COPY .github/workflows/build_gcc/step-2.4_download_mpc_source $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-2.4_download_mpc_source

COPY .github/workflows/build_gcc/step-2.6_download_linux_source $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-2.6_download_linux_source

ARG GCC_VERSION=15.2.0
COPY .github/workflows/build_gcc/step-2.5_download_gcc_source $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-2.5_download_gcc_source

COPY .github/workflows/build_gcc/step-3.1_install_linux_headers $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-3.1_install_linux_headers

COPY .github/workflows/build_gcc/step-3.2_install_binutils $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-3.2_install_binutils

COPY .github/workflows/build_gcc/step-3.3_install_libc $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-3.3_install_libc

COPY .github/workflows/build_gcc/step-3.4_install_gcc $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-3.4_install_gcc

COPY .github/workflows/build_gcc/step-4.1_build_gmp $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-4.1_build_gmp

COPY .github/workflows/build_gcc/step-4.2_build_isl $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-4.2_build_isl

COPY .github/workflows/build_gcc/step-4.3_build_mpfr $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-4.3_build_mpfr

COPY .github/workflows/build_gcc/step-4.4_build_mpc $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-4.4_build_mpc

COPY .github/workflows/build_gcc/step-4.5_build_gcc $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-4.5_build_gcc

COPY .github/workflows/build_gcc/step-5_package_toolchain $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-5_package_toolchain

CMD ["/bin/bash"]
