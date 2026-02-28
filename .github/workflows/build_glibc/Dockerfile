FROM ubuntu:latest

ARG GLIBC_VERSION=2.28
ARG LINUX_VERSION=6.18

# ===========
# || Setup ||
# ===========
ENV SCRIPTS_DIR="/tmp/scripts"
ENV UTILS_DIR="/tmp/scripts"

COPY .github/workflows/utils/initialize_user $UTILS_DIR/
RUN $UTILS_DIR/initialize_user

USER builder
WORKDIR /home/builder

COPY .github/workflows/build_glibc/environment $SCRIPTS_DIR/
COPY .github/workflows/utils/download_tarball $UTILS_DIR/

# =================
# || Build glibc ||
# =================
ARG TARGET=x86_64-linux-gnu

COPY .github/workflows/build_glibc/step-1_install_dependencies $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-1_install_dependencies

COPY .github/workflows/utils/install_gh_cli $UTILS_DIR/
RUN $UTILS_DIR/install_gh_cli

ARG GH_TOKEN
COPY .github/workflows/build_glibc/step-2.1_download_glibc_source $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-2.1_download_glibc_source

COPY .github/workflows/build_glibc/step-2.2_download_linux_source $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-2.2_download_linux_source

COPY .github/workflows/build_glibc/step-3.1_install_linux_headers $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-3.1_install_linux_headers

COPY .github/workflows/build_glibc/step-3.2_install_gcc $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-3.2_install_gcc

COPY .github/workflows/build_glibc/step-4_build_glibc $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-4_build_glibc

COPY .github/workflows/build_glibc/step-5_package_glibc $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-5_package_glibc
