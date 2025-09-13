FROM ubuntu:latest

# ==========================
# || Install Dependencies ||
# ==========================
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

# ========================
# || Build crosstool-ng ||
# ========================
RUN git clone https://github.com/crosstool-ng/crosstool-ng /opt/crosstool-ng
WORKDIR /opt/crosstool-ng
RUN ./bootstrap && \
    ./configure && \
    make && \
    make install

# ================
# || Create User||
# ================
RUN useradd -m -s /bin/bash builder && \
    usermod -aG sudo builder
RUN echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER builder
WORKDIR /home/builder

# ============================
# || Configure crosstool-ng ||
# ============================
ARG libc=gnu
ARG libc_version
ARG gcc_version=15
ARG rebuild_id=1

# Standard configs
RUN echo 'CT_CONFIG_VERSION="4"' > defconfig && \
    echo 'CT_ARCH_X86=y' >> defconfig && \
    echo 'CT_OMIT_TARGET_VENDOR=y' >> defconfig && \
    echo 'CT_ARCH_64=y' >> defconfig && \
    echo 'CT_STATIC_TOOLCHAIN=y' >> defconfig && \
    echo 'CT_KERNEL_LINUX=y' >> defconfig && \
    echo 'CT_LOG_PROGRESS_BAR=n' >> defconfig && \
    echo 'CT_PREFIX_DIR_RO=n' >> defconfig && \
    echo 'CT_CC_LANG_CXX=y' >> defconfig && \
    echo 'CT_DEBUG_GDB=y' >> defconfig && \
    echo 'CT_CC_GCC_LNK_HASH_STYLE_BOTH=y' >> defconfig

# GCC version configs
RUN if [ "$gcc_version" = "15" ]; then \
        echo 'CT_GCC_V_15=y' >> defconfig; \
    elif [ "$gcc_version" = "14" ]; then \
        echo 'CT_GCC_V_14=y' >> defconfig && \
        echo 'CT_GMP_EXTRA_CFLAGS="-std=gnu17"' >> defconfig && \
        echo 'CT_NCURSES_EXTRA_CFLAGS="-std=gnu17"' >> defconfig; \
    elif [ "$gcc_version" = "13" ]; then \
        echo 'CT_GCC_V_13=y' >> defconfig && \
        echo 'CT_GMP_EXTRA_CFLAGS="-std=gnu17"' >> defconfig && \
        echo 'CT_NCURSES_EXTRA_CFLAGS="-std=gnu17"' >> defconfig; \
    elif [ "$gcc_version" = "12" ]; then \
        echo 'CT_GCC_V_12=y' >> defconfig && \
        echo 'CT_GMP_EXTRA_CFLAGS="-std=gnu17"' >> defconfig && \
        echo 'CT_NCURSES_EXTRA_CFLAGS="-std=gnu17"' >> defconfig; \
    else \
        echo "Error: Unsupported gcc_version: $gcc_version" >&2 && \
        echo "Supported versions: 15, 14, 13, 12" >&2 && \
        exit 1; \
    fi

# glibc configs
RUN if [ "$libc" = "gnu" ]; then \
        echo 'CT_GLIBC_KERNEL_VERSION_NONE=y' >> defconfig; \
        if [ -n "$libc_version" ]; then \
            echo "CT_GLIBC_V_$(echo $libc_version | sed 's/\./_/g')=y" >> defconfig; \
        fi; \
    fi

# musl configs
RUN if [ "$libc" = "musl" ]; then \
        echo 'CT_LIBC_MUSL=y' >> defconfig; \
        if [ -n "$libc_version" ]; then \
            echo "CT_MUSL_V_$(echo $libc_version | sed 's/\./_/g')=y" >> defconfig; \
        fi; \
    fi

# =====================
# || Build Toolchain ||
# =====================
RUN ct-ng defconfig
RUN ct-ng build

# TODO: move these to toolchains_cc
# RUN cd /home/builder/x-tools/x86_64-linux-${libc}/x86_64-linux-${libc}/sysroot/lib && \
#     ln -s ../../../lib/gcc/ .

# RUN cd /home/builder/x-tools/x86_64-linux-${libc}/x86_64-linux-${libc}/sysroot/usr/include && \
#     ln -s ../../../include/c++/ .

# =======================
# || Package Toolchain ||
# =======================
RUN gcc_full_version=$(/home/builder/x-tools/x86_64-linux-${libc}/bin/x86_64-linux-${libc}-gcc --version | head -n1 | awk '{print $NF}') && \
    cd /home/builder/x-tools/x86_64-linux-${libc} && \
    XZ_OPT=-e9 tar cJf /home/builder/gcc-${gcc_full_version}-x86_64-linux-${libc}-r${rebuild_id}.tar.xz \
        bin/ \
        libexec/ \
        x86_64-linux-${libc}/lib/ \
        x86_64-linux-${libc}/bin/ && \
    XZ_OPT=-e9 tar cJf /home/builder/libgcc-${gcc_full_version}-x86_64-linux-${libc}-r${rebuild_id}.tar.xz \
        lib/ && \
    XZ_OPT=-e9 tar cJf /home/builder/libstdcxx-${gcc_full_version}-x86_64-linux-${libc}-r${rebuild_id}.tar.xz \
        x86_64-linux-${libc}/include/ \
        x86_64-linux-${libc}/lib64/ && \
    XZ_OPT=-e9 tar cJf /home/builder/sysroot-x86_64-linux-${libc}-r${rebuild_id}.tar.xz \
        x86_64-linux-${libc}/sysroot/
