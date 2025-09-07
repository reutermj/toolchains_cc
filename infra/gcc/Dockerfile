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
ARG libc=gnu
ARG libc_version
ARG cpp=yes
# ARG static=no
RUN echo 'CT_CONFIG_VERSION="4"' > defconfig && \
    echo 'CT_ARCH_X86=y' >> defconfig && \
    echo 'CT_OMIT_TARGET_VENDOR=y' >> defconfig && \
    echo 'CT_ARCH_64=y' >> defconfig && \
    echo 'CT_STATIC_TOOLCHAIN=y' >> defconfig && \
    echo 'CT_KERNEL_LINUX=y' >> defconfig && \
    echo 'CT_CC_GCC_LNK_HASH_STYLE_BOTH=y' >> defconfig && \
    echo '# CT_LIBC_XLDD is not set' >> defconfig

RUN if [ "$libc" = "gnu" ]; then \
        echo 'CT_GLIBC_KERNEL_VERSION_NONE=y' >> defconfig; \
        if [ -n "$libc_version" ]; then \
            echo "CT_GLIBC_V_$(echo $libc_version | sed 's/\./_/g')=y" >> defconfig; \
        fi; \
    fi

RUN if [ "$libc" = "musl" ]; then \
        echo 'CT_LIBC_MUSL=y' >> defconfig; \
        if [ -n "$libc_version" ]; then \
            echo "CT_MUSL_V_$(echo $libc_version | sed 's/\./_/g')=y" >> defconfig; \
        fi; \
    fi

# gdb requires c++. maybe gdb should be separated out as a build option
RUN if [ "$cpp" = "yes" ]; then \
        echo 'CT_CC_LANG_CXX=y' >> defconfig && \
        echo 'CT_DEBUG_GDB=y' >> defconfig; \
    fi

# works for musl but not for glibc. fails when configuring multilib.
# more holistically, do we care? can this be handled by suppling -static?
# RUN if [ "$static" = "yes" ]; then \
#         echo '# CT_SHARED_LIBS is not set' >> defconfig; \
#     fi

# Build the toolchain
RUN ct-ng defconfig
RUN ct-ng build

# Create tarballs of the toolchain components
# Create bin tarball (contents of bin directory without the bin/ prefix)
RUN cd /home/builder/x-tools/x86_64-linux-gnu && \
    XZ_OPT=-e9 tar cJf /home/builder/toolchain.tar.xz bin/ lib/ libexec/ share/

# Create sysroot tarball (contents of sysroot directory without the sysroot/ prefix)
RUN cd /home/builder/x-tools/x86_64-linux-gnu/x86_64-linux-gnu/sysroot && \
    XZ_OPT=-e9 tar cJf /home/builder/sysroot.tar.xz *

