FROM ubuntu:latest

# =================
# || Create User ||
# =================
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y sudo gh

RUN useradd -m -s /bin/bash builder && \
    usermod -aG sudo builder
RUN echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER builder
WORKDIR /home/builder

# =======================
# || Environment Setup ||
# =======================
ENV SCRIPTS_DIR="/tmp/scripts"

# =====================
# || Build Toolchain ||
# =====================
COPY step-1_install_dependencies $SCRIPTS_DIR/step-1_install_dependencies
RUN $SCRIPTS_DIR/step-1_install_dependencies

COPY environment $SCRIPTS_DIR/environment

COPY step-2_download_tarballs $SCRIPTS_DIR/step-2_download_tarballs
RUN $SCRIPTS_DIR/step-2_download_tarballs

COPY step-3_build_ncurses $SCRIPTS_DIR/step-3_build_ncurses
RUN $SCRIPTS_DIR/step-3_build_ncurses
