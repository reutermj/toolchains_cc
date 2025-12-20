FROM ubuntu:latest

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
ENV UTILS_DIR="/tmp/scripts"
COPY .github/workflows/build_musl/environment $SCRIPTS_DIR/environment
COPY .github/workflows/utils/download_tarball $UTILS_DIR/download_tarball

# ================
# || Build musl ||
# ================
COPY .github/workflows/build_musl/step-01_install_dependencies ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-01_install_dependencies

# Install newer GitHub CLI for attestation support (requires v2.47.0+)
# Ubuntu package version is too old, so install from GitHub releases
# We can assume the actions runner has a good enough version of gh so we only need it in the dockerfile
ARG GH_VERSION="2.63.2"
RUN wget "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" && \
    tar -xzf "gh_${GH_VERSION}_linux_amd64.tar.gz" && \
    sudo install "gh_${GH_VERSION}_linux_amd64/bin/gh" /usr/local/bin/gh

ARG GH_TOKEN
COPY .github/workflows/build_musl/step-02.1_download_gmp_source ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-02.1_download_gmp_source

COPY .github/workflows/build_musl/step-02.2_download_mpfr_source ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-02.2_download_mpfr_source

COPY .github/workflows/build_musl/step-02.3_download_isl_source ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-02.3_download_isl_source

COPY .github/workflows/build_musl/step-02.4_download_mpc_source ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-02.4_download_mpc_source

COPY .github/workflows/build_musl/step-02.5_download_gcc_source ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-02.5_download_gcc_source

COPY .github/workflows/build_musl/step-02.6_download_linux_source ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-02.6_download_linux_source

ARG MUSL_VERSION=1.2.5
COPY .github/workflows/build_musl/step-02.7_download_musl_source ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-02.7_download_musl_source

COPY .github/workflows/build_musl/step-02.8_download_binutils ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-02.8_download_binutils

COPY .github/workflows/build_musl/step-03_install_linux_headers ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-03_install_linux_headers

COPY .github/workflows/build_musl/step-04.1_build_gmp ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-04.1_build_gmp

COPY .github/workflows/build_musl/step-04.2_build_isl ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-04.2_build_isl

COPY .github/workflows/build_musl/step-04.3_build_mpfr ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-04.3_build_mpfr

COPY .github/workflows/build_musl/step-04.4_build_mpc ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-04.4_build_mpc

COPY .github/workflows/build_musl/step-05_build_core_gcc ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-05_build_core_gcc

COPY .github/workflows/build_musl/step-06_build_musl ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-06_build_musl

COPY .github/workflows/build_musl/step-07_package_musl ${SCRIPTS_DIR}/
RUN ${SCRIPTS_DIR}/step-07_package_musl
