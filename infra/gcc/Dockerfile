FROM ubuntu:latest

# Install crosstool-ng dependencies
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
        build-essential \
        autoconf \
        flex \
        bison \
        texinfo \
        help2man \
        file \
        gawk \
        libtool \
        libtool-bin \
        libncurses-dev \
        python3 \
        python3-dev \
        unzip \
        git \
        wget \
        curl \
        sudo

# Build and install crosstool-ng
RUN git clone https://github.com/crosstool-ng/crosstool-ng /opt/crosstool-ng
WORKDIR /opt/crosstool-ng
RUN ./bootstrap && \
    ./configure && \
    make && \
    make install

# Create user 
RUN useradd -m -s /bin/bash builder && \
    usermod -aG sudo builder
RUN echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER builder
WORKDIR /home/builder

# Configure the toolchain
RUN echo 'CT_CONFIG_VERSION="4"' > defconfig && \
    echo 'CT_ARCH_X86=y' >> defconfig && \
    echo 'CT_OMIT_TARGET_VENDOR=y' >> defconfig && \
    echo 'CT_ARCH_64=y' >> defconfig && \
    echo 'CT_STATIC_TOOLCHAIN=y' >> defconfig && \
    echo 'CT_KERNEL_LINUX=y' >> defconfig && \
    echo 'CT_GLIBC_KERNEL_VERSION_NONE=y' >> defconfig && \
    echo 'CT_CC_GCC_LNK_HASH_STYLE_BOTH=y' >> defconfig && \
    echo 'CT_CC_LANG_CXX=y' >> defconfig && \
    echo 'CT_DEBUG_GDB=y' >> defconfig

# Build the toolchain
RUN ct-ng defconfig
RUN ct-ng build
