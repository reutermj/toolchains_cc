FROM ubuntu:latest

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

COPY .github/workflows/build_linux_headers/environment $SCRIPTS_DIR/
COPY .github/workflows/utils/download_tarball $UTILS_DIR/

# =========================
# || Build Linux headers ||
# =========================
COPY .github/workflows/build_linux_headers/step-1_install_dependencies $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-1_install_dependencies

COPY .github/workflows/utils/install_gh_cli $UTILS_DIR/
RUN $UTILS_DIR/install_gh_cli

ARG GH_TOKEN
COPY .github/workflows/build_linux_headers/step-2_download_linux_source $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-2_download_linux_source

COPY .github/workflows/build_linux_headers/step-3_install_linux_headers $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-3_install_linux_headers

COPY .github/workflows/build_linux_headers/step-4_package_linux_headers $SCRIPTS_DIR/
RUN $SCRIPTS_DIR/step-4_package_linux_headers
