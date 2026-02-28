FROM ubuntu:latest

# ===========
# || Setup ||
# ===========
ENV SCRIPTS_DIR="/tmp/scripts"
ENV UTILS_DIR="/tmp/scripts"

COPY .github/workflows/utils/initialize_user ${UTILS_DIR}/
RUN ${UTILS_DIR}/initialize_user

USER builder
WORKDIR /home/builder

COPY .github/workflows/build_musl/environment ${SCRIPTS_DIR}/environment
COPY .github/workflows/utils/download_tarball ${UTILS_DIR}/download_tarball

# ================
# || Build musl ||
# ================
ARG TARGET=x86_64-linux-musl

COPY .github/workflows/build_musl/step-1_install_dependencies ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-1_install_dependencies

COPY .github/workflows/utils/install_gh_cli ${UTILS_DIR}/
RUN ${UTILS_DIR}/install_gh_cli

ARG GH_TOKEN
COPY .github/workflows/build_musl/step-2.1_download_linux_source ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-2.1_download_linux_source

ARG MUSL_VERSION=1.2.5
COPY .github/workflows/build_musl/step-2.2_download_musl_source ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-2.2_download_musl_source

COPY .github/workflows/build_musl/step-2.3_download_binutils ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-2.3_download_binutils

COPY .github/workflows/build_musl/step-2.4_download_gcc ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-2.4_download_gcc

COPY .github/workflows/build_musl/step-3_install_linux_headers ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-3_install_linux_headers

COPY .github/workflows/build_musl/step-4_build_musl ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-4_build_musl

COPY .github/workflows/build_musl/step-5_package_musl ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-5_package_musl
