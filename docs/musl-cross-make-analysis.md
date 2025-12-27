# Detailed Analysis of musl-cross-make GCC Build Process

This document provides a comprehensive breakdown of how the musl-cross-make repository builds GCC 15.1.0 to target musl libc.

**Analysis Version**: GCC 15.1.0 (modern toolchain)

## Key Changes in Modern GCC (15.1.0)

**Major improvements over GCC 9.4.0**:
- ✅ **9 patches** (down from 20+) - Many fixes upstreamed
- ✅ **Source migration** - GCC now uses C++ (`.cc` files)
- ✅ **Better musl integration** - Less patching required
- ✅ **Modern standards** - C23 and C++23 support
- ✅ **Improved optimization** - Better code generation

**Remaining patches** primarily address:
1. Core musl/glibc differences (SSP, static-pie)
2. Niche architectures (J2, M68k, SH FDPIC)
3. Build system compatibility (cowpatch)

See [Improvements in Modern GCC](#improvements-in-modern-gcc-1510-vs-940) for detailed comparison.

## Overview Architecture

The build system uses a two-tier Makefile structure:
1. **Top-level Makefile** ([musl-cross-make/Makefile](../musl-cross-make/Makefile)) - Downloads sources, extracts, patches, and delegates to litecross
2. **Litecross Makefile** ([musl-cross-make/litecross/Makefile](../musl-cross-make/litecross/Makefile)) - Orchestrates the complex multi-stage build

## Build Ordering - The Critical Bootstrap Sequence

The build follows a carefully orchestrated dependency chain to bootstrap a working cross-compiler:

### Stage 1: Binutils

**Location**: [litecross/Makefile:210-216](../musl-cross-make/litecross/Makefile#L210-L216)

```makefile
obj_binutils/.lc_configured: | obj_binutils src_binutils
    cd obj_binutils && ../src_binutils/configure $(FULL_BINUTILS_CONFIG)

obj_binutils/.lc_built: | obj_binutils/.lc_configured
    cd obj_binutils && $(MAKE) MAKE="$(MAKE) $(LIBTOOL_ARG)" all
```

**Configuration flags** (`FULL_BINUTILS_CONFIG`, lines 59-66):
- `--disable-separate-code` - Don't use separate code segment
- `--disable-werror` - Don't treat warnings as errors
- `--target=$(TARGET)` - Cross-compilation target (e.g., x86_64-linux-musl)
- `--prefix=` - Empty prefix (will be set during install)
- `--libdir=/lib` - Library directory
- `--disable-multilib` - Only build for one target, no multilib
- `--with-sysroot=$(SYSROOT)` - Use custom sysroot for target libraries
- `--enable-deterministic-archives` - Reproducible builds

**Purpose**: Builds the cross-assembler (`as`), linker (`ld`), and other binary utilities needed to build GCC and musl.

**Minimal replication script**:
```bash
#!/bin/bash
# Stage 1: Build Binutils
set -e

TARGET=x86_64-linux-musl
SYSROOT=/$(TARGET)

mkdir -p obj_binutils
cd obj_binutils

../src_binutils/configure \
  --disable-separate-code \
  --disable-werror \
  --target=${TARGET} \
  --prefix= \
  --libdir=/lib \
  --disable-multilib \
  --with-sysroot=${SYSROOT} \
  --enable-deterministic-archives \
  --build=$(../src_gcc/config.guess) \
  --host=$(../src_gcc/config.guess)

make -j$(nproc) \
  MULTILIB_OSDIRNAMES= \
  INFO_DEPS= \
  infodir= \
  MAKEINFO=false \
  all

cd ..
```

### Stage 2: GCC Stage 1 (Compiler Only)

**Location**: [litecross/Makefile:218-224](../musl-cross-make/litecross/Makefile#L218-L224)

```makefile
obj_gcc/.lc_configured: | obj_gcc src_gcc
    cd obj_gcc && ../src_gcc/configure $(FULL_GCC_CONFIG)

obj_gcc/gcc/.lc_built: | obj_gcc/.lc_configured
    cd obj_gcc && $(MAKE) MAKE="$(MAKE) $(LIBTOOL_ARG)" all-gcc
```

This builds **only the gcc compiler binary** (`all-gcc`), not the runtime libraries. The compiler is configured to point to newly-built binutils tools.

**Configuration flags** (`FULL_GCC_CONFIG`, lines 68-82):
- `--enable-languages=c,c++` - Only C and C++
- `$(GCC_CONFIG_FOR_TARGET)` - Target-specific flags (ABI, float, etc.)
- `--disable-bootstrap` - **Critical**: Don't do 3-stage bootstrap (we're cross-compiling)
- `--disable-assembly` - Don't use assembly optimizations
- `--disable-werror` - Don't treat warnings as errors
- `--target=$(TARGET)` - Cross-compilation target
- `--prefix=` - Empty prefix
- `--libdir=/lib` - Library directory
- `--disable-multilib` - Single-target only
- `--with-sysroot=$(SYSROOT)` - Use custom sysroot
- `--enable-tls` - Enable Thread-Local Storage
- `--disable-libmudflap` - Disable memory debugging library
- `--disable-libsanitizer` - Disable sanitizers
- `--disable-gnu-indirect-function` - **musl-specific**: musl doesn't support IFUNC
- `--disable-libmpx` - Disable Intel MPX
- `--enable-initfini-array` - Use .init_array/.fini_array (modern ELF)
- `--enable-libstdcxx-time=rt` - Use librt for std::chrono

**Host-specific flags** (lines 100-111):
- `--with-build-sysroot=$(CURDIR)/obj_sysroot` - Temporary sysroot for building
- `AR_FOR_TARGET=$(PWD)/obj_binutils/binutils/ar` - Use newly-built ar
- `AS_FOR_TARGET=$(PWD)/obj_binutils/gas/as-new` - Use newly-built assembler
- `LD_FOR_TARGET=$(PWD)/obj_binutils/ld/ld-new` - Use newly-built linker
- `NM_FOR_TARGET=$(PWD)/obj_binutils/binutils/nm-new` - Use newly-built nm
- `OBJCOPY_FOR_TARGET=$(PWD)/obj_binutils/binutils/objcopy` - Use newly-built objcopy
- `OBJDUMP_FOR_TARGET=$(PWD)/obj_binutils/binutils/objdump` - Use newly-built objdump
- `RANLIB_FOR_TARGET=$(PWD)/obj_binutils/binutils/ranlib` - Use newly-built ranlib
- `READELF_FOR_TARGET=$(PWD)/obj_binutils/binutils/readelf` - Use newly-built readelf
- `STRIP_FOR_TARGET=$(PWD)/obj_binutils/binutils/strip-new` - Use newly-built strip

**Critical**: These flags ensure GCC uses the newly-built binutils in `obj_binutils`, not system tools.

**Minimal replication script**:
```bash
#!/bin/bash
# Stage 2: Build GCC Stage 1 (compiler only)
set -e

TARGET=x86_64-linux-musl
SYSROOT=/$(TARGET)
PWD=$(pwd)

mkdir -p obj_gcc
cd obj_gcc

../src_gcc/configure \
  --enable-languages=c,c++ \
  --disable-bootstrap \
  --disable-assembly \
  --disable-werror \
  --target=${TARGET} \
  --prefix= \
  --libdir=/lib \
  --disable-multilib \
  --with-sysroot=${SYSROOT} \
  --enable-tls \
  --disable-libmudflap \
  --disable-libsanitizer \
  --disable-gnu-indirect-function \
  --disable-libmpx \
  --enable-initfini-array \
  --enable-libstdcxx-time=rt \
  --with-build-sysroot=${PWD}/obj_sysroot \
  AR_FOR_TARGET=${PWD}/obj_binutils/binutils/ar \
  AS_FOR_TARGET=${PWD}/obj_binutils/gas/as-new \
  LD_FOR_TARGET=${PWD}/obj_binutils/ld/ld-new \
  NM_FOR_TARGET=${PWD}/obj_binutils/binutils/nm-new \
  OBJCOPY_FOR_TARGET=${PWD}/obj_binutils/binutils/objcopy \
  OBJDUMP_FOR_TARGET=${PWD}/obj_binutils/binutils/objdump \
  RANLIB_FOR_TARGET=${PWD}/obj_binutils/binutils/ranlib \
  READELF_FOR_TARGET=${PWD}/obj_binutils/binutils/readelf \
  STRIP_FOR_TARGET=${PWD}/obj_binutils/binutils/strip-new \
  --build=$(../src_gcc/config.guess) \
  --host=$(../src_gcc/config.guess)

make -j$(nproc) \
  MULTILIB_OSDIRNAMES= \
  INFO_DEPS= \
  infodir= \
  ac_cv_prog_lex_root=lex.yy \
  MAKEINFO=false \
  all-gcc

cd ..
```

### Stage 3: Sysroot Preparation

**Location**: [litecross/Makefile:198-208](../musl-cross-make/litecross/Makefile#L198-L208), [line 116](../musl-cross-make/litecross/Makefile#L116)

```makefile
obj_sysroot/usr: | obj_sysroot
    ln -sf . $@

obj_sysroot/lib32: | obj_sysroot
    ln -sf lib $@

obj_sysroot/lib64: | obj_sysroot
    ln -sf lib $@

obj_gcc/gcc/.lc_built: | obj_sysroot/usr obj_sysroot/lib32 obj_sysroot/lib64 obj_sysroot/include
```

**Purpose**: Creates symlinks so paths like `/usr/include` and `/lib64` work correctly during the build.

**Minimal replication script**:
```bash
#!/bin/bash
# Stage 3: Sysroot Preparation
set -e

mkdir -p obj_sysroot/include
mkdir -p obj_sysroot/lib

# Create symlinks for compatibility
cd obj_sysroot
ln -sf . usr
ln -sf lib lib32
ln -sf lib lib64
cd ..
```

### Stage 4: musl Headers Installation

**Location**: [litecross/Makefile:226-232](../musl-cross-make/litecross/Makefile#L226-L232)

```makefile
obj_musl/.lc_configured: | obj_musl src_musl
    cd obj_musl && ../src_musl/configure $(FULL_MUSL_CONFIG)

obj_sysroot/.lc_headers: | obj_musl/.lc_configured obj_sysroot
    cd obj_musl && $(MAKE) DESTDIR=$(CURDIR)/obj_sysroot install-headers
```

**Configuration flags** (`FULL_MUSL_CONFIG`, lines 84-85):
- `--prefix=` - Empty prefix
- `--host=$(TARGET)` - Build for target architecture

**Purpose**: Installs musl's header files into `obj_sysroot/include` so GCC can find standard library headers when building libgcc.

**Minimal replication script**:
```bash
#!/bin/bash
# Stage 4: musl Headers Installation
set -e

TARGET=x86_64-linux-musl
PWD=$(pwd)

mkdir -p obj_musl
cd obj_musl

../src_musl/configure \
  --prefix= \
  --host=${TARGET}

make DESTDIR=${PWD}/obj_sysroot install-headers

cd ..
```

### Stage 5: libgcc (First Part - Static Only)

**Location**: [litecross/Makefile:234-235](../musl-cross-make/litecross/Makefile#L234-L235)

```makefile
obj_gcc/$(TARGET)/libgcc/libgcc.a: | obj_sysroot/.lc_headers
    cd obj_gcc && $(MAKE) MAKE="$(MAKE) enable_shared=no $(LIBTOOL_ARG)" all-target-libgcc
```

**Critical flags**:
- `enable_shared=no` - Build **only static libgcc**, not shared

**Purpose**: Builds `libgcc.a` which provides low-level runtime support:
- Integer arithmetic helpers (64-bit ops on 32-bit systems)
- Soft-float operations
- Exception handling support (stack unwinding)
- Thread-Local Storage support

This requires musl headers to compile but doesn't need the full musl library yet, breaking the circular dependency.

**Minimal replication script**:
```bash
#!/bin/bash
# Stage 5: Build libgcc (static only)
set -e

TARGET=x86_64-linux-musl

cd obj_gcc

make -j$(nproc) \
  MULTILIB_OSDIRNAMES= \
  INFO_DEPS= \
  infodir= \
  ac_cv_prog_lex_root=lex.yy \
  MAKEINFO=false \
  enable_shared=no \
  all-target-libgcc

cd ..
```

### Stage 6: musl Library

**Location**: [litecross/Makefile:237-243](../musl-cross-make/litecross/Makefile#L237-L243)

```makefile
obj_musl/.lc_built: | obj_musl/.lc_configured
    cd obj_musl && $(MAKE) $(MUSL_VARS)

obj_sysroot/.lc_libs: | obj_musl/.lc_built
    cd obj_musl && $(MAKE) $(MUSL_VARS) DESTDIR=$(CURDIR)/obj_sysroot install
```

**Build variables** (`MUSL_VARS`, line 113):
- `AR=../obj_binutils/binutils/ar` - Use our binutils
- `RANLIB=../obj_binutils/binutils/ranlib` - Use our binutils

**Configuration** (from line 112):
- `CC="$(XGCC)"` - Use the stage-1 GCC we just built
- `LIBCC="../obj_gcc/$(TARGET)/libgcc/libgcc.a"` - Use the libgcc we just built

**XGCC definition** (lines 13-14):
```makefile
XGCC_DIR = ../obj_gcc/gcc
XGCC = $(XGCC_DIR)/xgcc -B $(XGCC_DIR)
```

`xgcc` is the just-built cross-compiler, and `-B` tells it where to find its own components.

**Purpose**: Builds the complete musl C library using:
- The stage-1 GCC compiler
- The static libgcc.a
- The newly-built binutils

**Minimal replication script**:
```bash
#!/bin/bash
# Stage 6: Build musl Library
set -e

TARGET=x86_64-linux-musl
PWD=$(pwd)
XGCC_DIR=${PWD}/obj_gcc/gcc
XGCC="${XGCC_DIR}/xgcc -B ${XGCC_DIR}"

cd obj_musl

# Build musl
make -j$(nproc) \
  CC="${XGCC}" \
  LIBCC="${PWD}/obj_gcc/${TARGET}/libgcc/libgcc.a" \
  AR=${PWD}/obj_binutils/binutils/ar \
  RANLIB=${PWD}/obj_binutils/binutils/ranlib

# Install to sysroot
make \
  AR=${PWD}/obj_binutils/binutils/ar \
  RANLIB=${PWD}/obj_binutils/binutils/ranlib \
  DESTDIR=${PWD}/obj_sysroot \
  install

cd ..
```

### Stage 7: GCC Full Build

**Location**: [litecross/Makefile:245-247](../musl-cross-make/litecross/Makefile#L245-L247)

```makefile
obj_gcc/.lc_built: | obj_gcc/.lc_configured obj_gcc/gcc/.lc_built
    cd obj_gcc && $(MAKE) MAKE="$(MAKE) $(LIBTOOL_ARG)"
```

**Purpose**: Now that musl is fully built and installed in the sysroot, GCC can build:
- Shared libgcc (`libgcc_s.so`)
- C++ standard library (`libstdc++`)
- Other language runtime libraries

**Minimal replication script**:
```bash
#!/bin/bash
# Stage 7: GCC Full Build
set -e

cd obj_gcc

# Build complete GCC with all runtime libraries
make -j$(nproc) \
  MULTILIB_OSDIRNAMES= \
  INFO_DEPS= \
  infodir= \
  ac_cv_prog_lex_root=lex.yy \
  MAKEINFO=false

cd ..
```

### Complete Bootstrap with Dockerfile

Here's a Dockerfile that orchestrates all 7 stages:

```dockerfile
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
ENV TARGET="x86_64-linux-musl"
ENV SYSROOT="/${TARGET}"

# =================
# || Build Toolchain ||
# =================

# Install dependencies
COPY .github/workflows/build_gcc_muslinstall_dependencies $SCRIPTS_DIR/install_dependencies
RUN $SCRIPTS_DIR/install_dependencies

# Download sources
COPY .github/workflows/build_gcc_musldownload_binutils $SCRIPTS_DIR/download_binutils
RUN $SCRIPTS_DIR/download_binutils

COPY .github/workflows/build_gcc_musldownload_gcc $SCRIPTS_DIR/download_gcc
RUN $SCRIPTS_DIR/download_gcc

# Apply GCC patches
COPY musl-cross-make/patches/gcc-15.1.0 /tmp/gcc-patches
COPY .github/workflows/build_gcc_muslapply_gcc_patches $SCRIPTS_DIR/apply_gcc_patches
RUN $SCRIPTS_DIR/apply_gcc_patches

COPY .github/workflows/build_gcc_musldownload_musl $SCRIPTS_DIR/download_musl
RUN $SCRIPTS_DIR/download_musl

COPY .github/workflows/build_gcc_musldownload_gmp $SCRIPTS_DIR/download_gmp
RUN $SCRIPTS_DIR/download_gmp

COPY .github/workflows/build_gcc_musldownload_mpc $SCRIPTS_DIR/download_mpc
RUN $SCRIPTS_DIR/download_mpc

COPY .github/workflows/build_gcc_musldownload_mpfr $SCRIPTS_DIR/download_mpfr
RUN $SCRIPTS_DIR/download_mpfr

# Stage 1: Build Binutils
COPY .github/workflows/build_gcc_muslstage1_build_binutils $SCRIPTS_DIR/stage1_build_binutils
RUN $SCRIPTS_DIR/stage1_build_binutils

# Stage 2: Build GCC Compiler Only
COPY .github/workflows/build_gcc_muslstage2_build_gcc_compiler $SCRIPTS_DIR/stage2_build_gcc_compiler
RUN $SCRIPTS_DIR/stage2_build_gcc_compiler

# Stage 3: Prepare Sysroot
COPY .github/workflows/build_gcc_muslstage3_prepare_sysroot $SCRIPTS_DIR/stage3_prepare_sysroot
RUN $SCRIPTS_DIR/stage3_prepare_sysroot

# Stage 4: Install musl Headers
COPY .github/workflows/build_gcc_muslstage4_install_musl_headers $SCRIPTS_DIR/stage4_install_musl_headers
RUN $SCRIPTS_DIR/stage4_install_musl_headers

# Stage 5: Build libgcc (static only)
COPY .github/workflows/build_gcc_muslstage5_build_libgcc $SCRIPTS_DIR/stage5_build_libgcc
RUN $SCRIPTS_DIR/stage5_build_libgcc

# Stage 6: Build musl Library
COPY .github/workflows/build_gcc_muslstage6_build_musl $SCRIPTS_DIR/stage6_build_musl
RUN $SCRIPTS_DIR/stage6_build_musl

# Stage 7: Build Complete GCC
COPY .github/workflows/build_gcc_muslstage7_build_full_gcc $SCRIPTS_DIR/stage7_build_full_gcc
RUN $SCRIPTS_DIR/stage7_build_full_gcc

# Package final toolchain
COPY .github/workflows/build_gcc_muslpackage_toolchain $SCRIPTS_DIR/package_toolchain
RUN $SCRIPTS_DIR/package_toolchain
```

**Supporting Scripts** (in `.github/workflows/build_gcc_musl` directory):

```
.github/workflows/build_gcc_muslinstall_dependencies
```
```bash
#!/bin/bash
set -e
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    build-essential \
    wget \
    texinfo \
    bison \
    flex \
    libgmp-dev \
    libmpfr-dev \
    libmpc-dev \
    file
```

```
.github/workflows/build_gcc_musldownload_binutils
```
```bash
#!/bin/bash
set -e
BINUTILS_VERSION=2.44
wget "https://ftpmirror.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz"
tar -xf "binutils-${BINUTILS_VERSION}.tar.xz"
mv "binutils-${BINUTILS_VERSION}" src_binutils
```

```
.github/workflows/build_gcc_musldownload_gcc
```
```bash
#!/bin/bash
set -e
GCC_VERSION=15.1.0
wget "https://ftpmirror.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz"
tar -xf "gcc-${GCC_VERSION}.tar.xz"
mv "gcc-${GCC_VERSION}" src_gcc
```

**Note**: Patches are applied separately in a dedicated script to match musl-cross-make's build process.

```
.github/workflows/build_gcc_muslapply_gcc_patches
```
```bash
#!/bin/bash
set -e
cd src_gcc
# Apply all patches in order
for patch in /tmp/gcc-patches/*.diff; do
    patch -p1 < "$patch"
done
cd ..
```

**Patches applied** (from [musl-cross-make/patches/gcc-15.1.0/](../musl-cross-make/patches/gcc-15.1.0/)):
- `0001-ssp_nonshared.diff` - Stack protection linking
- `0002-posix_memalign.diff` - SSE/AVX intrinsics namespace fix
- `0003-j2.diff` - J2 CPU support (SuperH architecture)
- `0004-static-pie.diff` - Static PIE support
- `0005-m68k-sqrt.diff` - M68k sqrt fix
- `0006-cow-libstdc++v3.diff` - Build system compatibility
- `0007-fdpic-unwind.diff` - FDPIC unwinding support
- `0008-fdpic-crtstuff-pr114158.diff` - FDPIC crtstuff fix
- `0009-sh-fdpic-pr114641.diff` - SuperH FDPIC fix

Only patches 1, 2, 4, and 6 affect x86_64 builds.

```
.github/workflows/build_gcc_musldownload_musl
```
```bash
#!/bin/bash
set -e
MUSL_VERSION=1.2.5
wget "https://musl.libc.org/releases/musl-${MUSL_VERSION}.tar.gz"
tar -xf "musl-${MUSL_VERSION}.tar.gz"
mv "musl-${MUSL_VERSION}" src_musl
```

```
.github/workflows/build_gcc_musldownload_gmp
```
```bash
#!/bin/bash
set -e
GMP_VERSION=6.3.0
wget "https://ftpmirror.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.xz"
tar -xf "gmp-${GMP_VERSION}.tar.xz"
mv "gmp-${GMP_VERSION}" src_gmp
cd src_gcc && ln -sf ../src_gmp gmp
```

```
.github/workflows/build_gcc_musldownload_mpc
```
```bash
#!/bin/bash
set -e
MPC_VERSION=1.3.1
wget "https://ftpmirror.gnu.org/gnu/mpc/mpc-${MPC_VERSION}.tar.gz"
tar -xf "mpc-${MPC_VERSION}.tar.gz"
mv "mpc-${MPC_VERSION}" src_mpc
cd src_gcc && ln -sf ../src_mpc mpc
```

```
.github/workflows/build_gcc_musldownload_mpfr
```
```bash
#!/bin/bash
set -e
MPFR_VERSION=4.2.2
wget "https://ftpmirror.gnu.org/gnu/mpfr/mpfr-${MPFR_VERSION}.tar.xz"
tar -xf "mpfr-${MPFR_VERSION}.tar.xz"
mv "mpfr-${MPFR_VERSION}" src_mpfr
cd src_gcc && ln -sf ../src_mpfr mpfr
```

```
.github/workflows/build_gcc_muslstage1_build_binutils
```
```bash
#!/bin/bash
set -e
mkdir -p obj_binutils
cd obj_binutils
../src_binutils/configure \
  --disable-separate-code \
  --disable-werror \
  --target=${TARGET} \
  --prefix= \
  --libdir=/lib \
  --disable-multilib \
  --with-sysroot=${SYSROOT} \
  --enable-deterministic-archives \
  --build=$(../src_gcc/config.guess) \
  --host=$(../src_gcc/config.guess)
make -j$(nproc) MULTILIB_OSDIRNAMES= INFO_DEPS= infodir= MAKEINFO=false all
```

```
.github/workflows/build_gcc_muslstage2_build_gcc_compiler
```
```bash
#!/bin/bash
set -e
PWD=$(pwd)
mkdir -p obj_gcc
cd obj_gcc
../src_gcc/configure \
  --enable-languages=c,c++ \
  --disable-bootstrap \
  --disable-assembly \
  --disable-werror \
  --target=${TARGET} \
  --prefix= \
  --libdir=/lib \
  --disable-multilib \
  --with-sysroot=${SYSROOT} \
  --enable-tls \
  --disable-libmudflap \
  --disable-libsanitizer \
  --disable-gnu-indirect-function \
  --disable-libmpx \
  --enable-initfini-array \
  --enable-libstdcxx-time=rt \
  --with-build-sysroot=${PWD}/obj_sysroot \
  AR_FOR_TARGET=${PWD}/obj_binutils/binutils/ar \
  AS_FOR_TARGET=${PWD}/obj_binutils/gas/as-new \
  LD_FOR_TARGET=${PWD}/obj_binutils/ld/ld-new \
  NM_FOR_TARGET=${PWD}/obj_binutils/binutils/nm-new \
  OBJCOPY_FOR_TARGET=${PWD}/obj_binutils/binutils/objcopy \
  OBJDUMP_FOR_TARGET=${PWD}/obj_binutils/binutils/objdump \
  RANLIB_FOR_TARGET=${PWD}/obj_binutils/binutils/ranlib \
  READELF_FOR_TARGET=${PWD}/obj_binutils/binutils/readelf \
  STRIP_FOR_TARGET=${PWD}/obj_binutils/binutils/strip-new \
  --build=$(../src_gcc/config.guess) \
  --host=$(../src_gcc/config.guess)
make -j$(nproc) MULTILIB_OSDIRNAMES= INFO_DEPS= infodir= \
  ac_cv_prog_lex_root=lex.yy MAKEINFO=false all-gcc
```

```
.github/workflows/build_gcc_muslstage3_prepare_sysroot
```
```bash
#!/bin/bash
set -e
mkdir -p obj_sysroot/include obj_sysroot/lib
cd obj_sysroot
ln -sf . usr
ln -sf lib lib32
ln -sf lib lib64
```

```
.github/workflows/build_gcc_muslstage4_install_musl_headers
```
```bash
#!/bin/bash
set -e
PWD=$(pwd)
mkdir -p obj_musl
cd obj_musl
../src_musl/configure --prefix= --host=${TARGET}
make DESTDIR=${PWD}/obj_sysroot install-headers
```

```
.github/workflows/build_gcc_muslstage5_build_libgcc
```
```bash
#!/bin/bash
set -e
cd obj_gcc
make -j$(nproc) MULTILIB_OSDIRNAMES= INFO_DEPS= infodir= \
  ac_cv_prog_lex_root=lex.yy MAKEINFO=false enable_shared=no \
  all-target-libgcc
```

```
.github/workflows/build_gcc_muslstage6_build_musl
```
```bash
#!/bin/bash
set -e
PWD=$(pwd)
XGCC_DIR=${PWD}/obj_gcc/gcc
XGCC="${XGCC_DIR}/xgcc -B ${XGCC_DIR}"
cd obj_musl
make -j$(nproc) \
  CC="${XGCC}" \
  LIBCC="${PWD}/obj_gcc/${TARGET}/libgcc/libgcc.a" \
  AR=${PWD}/obj_binutils/binutils/ar \
  RANLIB=${PWD}/obj_binutils/binutils/ranlib
make \
  AR=${PWD}/obj_binutils/binutils/ar \
  RANLIB=${PWD}/obj_binutils/binutils/ranlib \
  DESTDIR=${PWD}/obj_sysroot \
  install
```

```
.github/workflows/build_gcc_muslstage7_build_full_gcc
```
```bash
#!/bin/bash
set -e
cd obj_gcc
make -j$(nproc) MULTILIB_OSDIRNAMES= INFO_DEPS= infodir= \
  ac_cv_prog_lex_root=lex.yy MAKEINFO=false
```

```
.github/workflows/build_gcc_muslpackage_toolchain
```
```bash
#!/bin/bash
set -e
mkdir -p output
cd obj_gcc
make DESTDIR=/home/builder/output install
cd ../obj_musl
make DESTDIR=/home/builder/output/${TARGET} install
cd ../obj_binutils
make DESTDIR=/home/builder/output install
cd ..
tar -czf output/x86_64-linux-musl-toolchain.tar.gz -C output .
```

**Build**:
```bash
docker build -t musl-gcc-toolchain .
```

## x86_64 Configuration

For standard x86_64-linux-musl targets, **no special ABI flags are needed**. The configuration uses standard System V AMD64 ABI:

- **ABI**: System V AMD64 (default)
- **Calling convention**: RDI, RSI, RDX, RCX, R8, R9 for first 6 integer args
- **Float ABI**: Hardware floating point (SSE/SSE2)
- **Long double**: 80-bit x87 extended precision
- **Position Independent Code**: Enabled by default for shared libraries

The Makefile contains conditional logic for other architectures (x32, ARM, MIPS, PowerPC, etc.) but these are not needed for standard x86_64.

## Critical GCC Patches for musl (x86_64)

For **x86_64-linux-musl**, only **4 patches** are required (GCC 15.1.0 has 5 additional patches for niche architectures that are not listed here):

### 1. SSP (Stack Smashing Protection) - 0001-ssp_nonshared.diff

**Problem**: musl doesn't provide SSP symbols in libc itself; they're in a separate library `libssp_nonshared.a`.

**Solution**: Links `-lssp_nonshared` when stack protector flags are used:
```diff
 #define LINK_SSP_SPEC "%{fstack-protector|fstack-protector-all" \
-		       "|fstack-protector-strong|fstack-protector-explicit:}"
+		       "|fstack-protector-strong|fstack-protector-explicit" \
+		       ":-lssp_nonshared}"
```

**Changed in GCC 15**: File moved from `gcc/gcc.c` to `gcc/gcc.cc` (C++ source now)

This ensures that when you compile with `-fstack-protector`, the necessary runtime symbols (`__stack_chk_fail`, `__stack_chk_guard`) are linked from `libssp_nonshared.a`.

### 2. posix_memalign Namespace Pollution - 0002-posix_memalign.diff

**Problem**: GCC's `_mm_malloc.h` header (used for SSE/AVX intrinsics) declares `posix_memalign()` which can conflict with musl's definition and pollute the namespace.

**Solution**: Renames to `_mm_posix_memalign` with inline assembly alias:
```c
-extern int posix_memalign (void **, size_t, size_t);
+extern int _mm_posix_memalign (void **, size_t, size_t)
+__asm__("posix_memalign");
```

**Status in GCC 15**: Still required, no changes from earlier versions.

This prevents namespace pollution while still calling the correct function at link time. The assembly alias ensures the symbol resolves to `posix_memalign` from musl.

### 3. Static PIE Support - 0004-static-pie.diff

**Problem**: GCC's static-pie implementation assumes glibc-specific behaviors. musl handles static PIE differently.

**Solution**: Multiple coordinated changes:

#### PIE Spec Definition
```diff
-#define PIE_SPEC		"pie"
+#define PIE_SPEC		"pie|static-pie"
```
Makes both `-pie` and `-static-pie` trigger PIE code generation.

#### Linker Flags
```diff
-#define LD_PIE_SPEC "-pie"
+#define LD_PIE_SPEC "-pie %{static|static-pie:--no-dynamic-linker -z text -Bsymbolic -static}"
```
For static PIE:
- `--no-dynamic-linker` - Don't embed dynamic linker path
- `-z text` - Ensure no text relocations (required for PIE)
- `-Bsymbolic` - Bind references to global symbols to the definition within the executable
- `-static` - Don't link against shared libraries

#### Startup Files (CRT objects)
```diff
 GNU_USER_TARGET_STARTFILE_SPEC \
   "%{shared:; \
      pg|p|profile:%{static-pie:grcrt1.o%s;:gcrt1.o%s}; \
-     static:crt1.o%s; \
-     static-pie:rcrt1.o%s; \
+     static|static-pie:%{" PIE_SPEC ":rcrt1.o%s;:crt1.o%s}; \
      " PIE_SPEC ":Scrt1.o%s; \
      :crt1.o%s} "
```

Startup file selection for musl:
- `rcrt1.o` - PIE static executable (relocatable)
- `Scrt1.o` - PIE dynamic executable
- `crt1.o` - Non-PIE static/dynamic executable
- `gcrt1.o` - Profiling

#### Constructor/Destructor Objects
```diff
-   %{static:crtbeginT.o%s; \
-     shared|static-pie|" PIE_SPEC ":crtbeginS.o%s; \
+   %{shared|" PIE_SPEC ":crtbeginS.o%s; \
+     static:crtbeginT.o%s; \
      :crtbegin.o%s}
```

- `crtbeginS.o` / `crtendS.o` - PIE and shared libraries (PIC code)
- `crtbeginT.o` / `crtend.o` - Static non-PIE executables

#### vtable Verification Fix
```diff
 GNU_USER_TARGET_ENDFILE_SPEC \
-  "%{!static:%{fvtable-verify=none:%s; \
+  "%{static|static-pie:; \
+     fvtable-verify=none:%s; \
      fvtable-verify=preinit:vtv_end_preinit.o%s; \
-     fvtable-verify=std:vtv_end.o%s}} \
+     fvtable-verify=std:vtv_end.o%s} \
```

**New in GCC 15**: Additional fix for vtable verification with static-pie to prevent linking the wrong vtv objects.

**Status in GCC 15**: Still required, with improvements for vtable verification.

### 4. libstdc++ Copy-on-Write Fix - 0006-cow-libstdc++v3.diff

**Problem**: Minor whitespace issue in libstdc++ ChangeLog that can cause cowpatch issues.

**Solution**: Removes trailing whitespace from ChangeLog notice line.

**Technical detail**: This is a cowpatch-specific fix - the copy-on-write patch system is sensitive to file changes.

---

### Additional Configuration: GNU Indirect Function (IFUNC) Disabling

**Flag**: `--disable-gnu-indirect-function`

**Problem**: IFUNC is a glibc-specific dynamic linking feature that allows runtime selection of function implementations (e.g., choosing SSE4.2 vs. AVX2 version of `memcpy`).

**Why disabled for musl**:
- musl's dynamic linker doesn't support IFUNC resolution
- Enabling IFUNC would generate binaries incompatible with musl
- musl prefers smaller code size over micro-optimizations

**Status in GCC 15**: Still required, no upstream changes.

---

### Summary: x86_64 Patch Requirements

**Complete list for x86_64-linux-musl**:

| # | Patch | Purpose |
|---|-------|---------|
| 1 | 0001-ssp_nonshared.diff | Stack protection linking |
| 2 | 0002-posix_memalign.diff | SSE/AVX intrinsics namespace fix |
| 3 | 0004-static-pie.diff | Static PIE support |
| 4 | 0006-cow-libstdc++v3.diff | Build system (cowpatch) compatibility |

**Note**: GCC 15.1.0 includes 5 additional patches (0003, 0005, 0007, 0008, 0009) for other architectures (J2, M68k, SuperH FDPIC). These are applied during the build but have no effect on x86_64 binaries.

## Build System Variables

**Key Make variables** ([lines 54-57](../musl-cross-make/litecross/Makefile#L54-L57)):
```makefile
MAKE += MULTILIB_OSDIRNAMES=
MAKE += INFO_DEPS= infodir=
MAKE += ac_cv_prog_lex_root=lex.yy
MAKE += MAKEINFO=false
```

- `MULTILIB_OSDIRNAMES=` - Disable multilib OS directory names (we're single-target)
- `INFO_DEPS= infodir=` - Don't build info documentation
- `ac_cv_prog_lex_root=lex.yy` - Skip autoconf lex detection (use default)
- `MAKEINFO=false` - Don't require makeinfo tool (skip texinfo docs)

These speed up the build and reduce dependencies.

## Source Preparation (Top-Level Makefile)

### Download & Verification

**Location**: [Makefile:75-93](../musl-cross-make/Makefile#L75-L93)

```makefile
$(SOURCES)/%: hashes/%.sha1 | $(SOURCES)
    mkdir -p $@.tmp
    cd $@.tmp && $(DL_CMD) $(notdir $@) $(SITE)/$(notdir $@)
    cd $@.tmp && touch $(notdir $@)
    cd $@.tmp && $(SHA1_CMD) $(CURDIR)/hashes/$(notdir $@).sha1
    mv $@.tmp/$(notdir $@) $@
    rm -rf $@.tmp
```

**Process**:
1. Creates temporary directory
2. Downloads tarball from GNU mirrors or musl.libc.org
3. Verifies SHA1 checksum against `hashes/*.sha1`
4. Moves to final location only if verification succeeds

**Security**: Every source tarball is cryptographically verified, preventing supply chain attacks.

### Extraction

**Location**: [Makefile:105-133](../musl-cross-make/Makefile#L105-L133)

```makefile
%.orig: $(SOURCES)/%.tar.xz
    case "$@" in */*) exit 1 ;; esac
    rm -rf $@.tmp
    mkdir $@.tmp
    ( cd $@.tmp && tar Jxvf - ) < $<
    rm -rf $@
    touch $@.tmp/$(patsubst %.orig,%,$@)
    mv $@.tmp/$(patsubst %.orig,%,$@) $@
    rm -rf $@.tmp
```

Supports `.tar.gz`, `.tar.bz2`, and `.tar.xz` formats. Creates `.orig` directories with pristine sources.

### Patching with cowpatch

**Location**: [Makefile:135-142](../musl-cross-make/Makefile#L135-L142)

```makefile
%: %.orig
    case "$@" in */*) exit 1 ;; esac
    rm -rf $@.tmp
    mkdir $@.tmp
    ( cd $@.tmp && $(COWPATCH) -I ../$< )
    test ! -d patches/$@ || cat patches/$@/* | ( cd $@.tmp && $(COWPATCH) -p1 )
    rm -rf $@
    mv $@.tmp $@
```

**cowpatch.sh** is a copy-on-write patch tool that:
1. Creates symlinks to original source (`-I ../$<`)
2. Only copies files that get modified by patches
3. Applies all patches from `patches/<component>/` directory in order

**Benefits**:
- Saves disk space (most files are symlinks)
- Faster than full source copy
- Clear separation between pristine and patched sources

### GCC Dependency Linking

**Location**: [Makefile:185-193](../musl-cross-make/Makefile#L185-L193)

```makefile
src_gcc: src_gcc_base
    rm -rf $@ $@.tmp
    mkdir $@.tmp
    cd $@.tmp && ln -sf ../src_gcc_base/* .
    $(if $(GMP_SRCDIR),cd $@.tmp && ln -sf ../src_gmp gmp)
    $(if $(MPC_SRCDIR),cd $@.tmp && ln -sf ../src_mpc mpc)
    $(if $(MPFR_SRCDIR),cd $@.tmp && ln -sf ../src_mpfr mpfr)
    $(if $(ISL_SRCDIR),cd $@.tmp && ln -sf ../src_isl isl)
    mv $@.tmp $@
```

**Purpose**: GCC's build system expects its math library dependencies (GMP, MPC, MPFR, ISL) as subdirectories within the GCC source tree. This creates a composite source tree:

```
src_gcc/
├── gcc/ -> ../src_gcc_base/gcc/
├── libgcc/ -> ../src_gcc_base/libgcc/
├── gmp -> ../src_gmp/
├── mpc -> ../src_mpc/
├── mpfr -> ../src_mpfr/
└── isl -> ../src_isl/
```

This enables GCC's `--with-gmp=in-tree` behavior without copying sources.

## Installation

**Location**: [litecross/Makefile:249-257](../musl-cross-make/litecross/Makefile#L249-L257)

```makefile
install-musl: | obj_musl/.lc_built
    cd obj_musl && $(MAKE) $(MUSL_VARS) DESTDIR=$(DESTDIR)$(OUTPUT)$(SYSROOT) install

install-binutils: | obj_binutils/.lc_built
    cd obj_binutils && $(MAKE) MAKE="$(MAKE) $(LIBTOOL_ARG)" DESTDIR=$(DESTDIR)$(OUTPUT) install

install-gcc: | obj_gcc/.lc_built
    cd obj_gcc && $(MAKE) MAKE="$(MAKE) $(LIBTOOL_ARG)" DESTDIR=$(DESTDIR)$(OUTPUT) install
    ln -sf $(TARGET)-gcc $(DESTDIR)$(OUTPUT)/bin/$(TARGET)-cc
```

**Layout**:
- Binutils: `$(OUTPUT)/bin/`, `$(OUTPUT)/lib/`
- GCC: `$(OUTPUT)/bin/`, `$(OUTPUT)/lib/gcc/`, `$(OUTPUT)/include/`
- musl: `$(OUTPUT)/$(TARGET)/lib/`, `$(OUTPUT)/$(TARGET)/include/`

**Symlink**: Creates `$(TARGET)-cc` symlink to `$(TARGET)-gcc` for compatibility.

## Summary: The Bootstrap Dance

The complete build flow solves the circular dependency problem:

```
1. Extract & patch sources
   ├── Apply musl-specific GCC patches
   └── Verify all checksums
   ↓
2. Build binutils (cross-assembler, linker, etc.)
   └── Tools for TARGET architecture
   ↓
3. Configure GCC with musl-specific flags
   ├── --disable-gnu-indirect-function
   ├── --disable-bootstrap
   └── Point to obj_binutils tools
   ↓
4. Build GCC compiler only (all-gcc)
   └── Just the gcc binary, no runtime libs
   ↓
5. Configure musl
   └── For TARGET architecture
   ↓
6. Install musl headers to obj_sysroot
   └── Provides standard library API
   ↓
7. Build libgcc.a (static only)
   ├── Uses musl headers
   ├── enable_shared=no
   └── Provides low-level runtime support
   ↓
8. Build musl library
   ├── CC=xgcc (stage-1 compiler)
   ├── LIBCC=libgcc.a (just built)
   └── AR/RANLIB from obj_binutils
   ↓
9. Install musl to obj_sysroot
   └── Now have complete C library
   ↓
10. Build complete GCC
    ├── libgcc_s.so (shared libgcc)
    ├── libstdc++ (C++ standard library)
    └── Other runtime libraries
    ↓
11. Install everything to output directory
    └── Complete cross-toolchain ready
```

## Key Insights

### The Chicken-and-Egg Problem

GCC needs libc headers → to build libgcc
libgcc is needed → to build musl
musl is needed → to build full GCC runtime

**Solution**: Staged build with minimal bootstrap:
1. Build GCC compiler without runtime libs
2. Install just musl headers (no compiled code)
3. Build static-only libgcc
4. Build musl using stage-1 GCC + static libgcc
5. Build complete GCC with full runtime

### Why --disable-bootstrap?

Normal GCC build does a 3-stage bootstrap:
1. Build GCC with system compiler
2. Rebuild GCC with stage-1 GCC
3. Rebuild GCC with stage-2 GCC to verify reproducibility

**For cross-compilation**: Bootstrap is unnecessary and impossible (can't run cross-compiled binaries on build system). We build once with the system compiler.

### Why enable_shared=no for first libgcc?

Shared libgcc (`libgcc_s.so`) requires:
- Dynamic linker path
- C library for initialization
- Thread-Local Storage support from libc

At stage 5, we have musl headers but not the compiled library. Building shared libgcc would fail or produce incorrect binaries. Static-only libgcc provides enough support to build musl, then we can build shared libgcc.

### Why musl-specific patches matter

GCC is heavily optimized for glibc. Without patches:
- Stack protection would fail to link (`-lssp_nonshared`)
- Static PIE would use wrong startup files
- IFUNC would generate incompatible binaries
- Namespace pollution from internal headers

The patches adapt GCC's assumptions to musl's minimalist design.

## Improvements in Modern GCC (15.1.0 vs 9.4.0)

### Patches Reduced from 20 to 9

Many musl-specific fixes have been upstreamed into GCC over the years:

**Removed patches (now upstream in GCC 15)**:
- `libatomic-test-fix.diff` - Test fixes integrated
- `libgomp-test-fix.diff` - OpenMP test fixes integrated
- `libitm-test-fix.diff` - Transactional memory test fixes integrated
- `libvtv-test-fix.diff` - vtable verification test fixes integrated
- `libstdc++-futex-time64.diff` - time64 support now standard
- `ldbl128-config.diff` - long double configuration improved
- `m68k.diff` - General m68k fixes integrated
- `invalid-tls-model.diff` - TLS model validation improved
- `fix-gthr-weak-refs-for-libgcc.patch` - Threading fixes integrated
- `riscv-tls-copy-relocs.diff` - RISC-V TLS fixes integrated
- `broken-builtin-memcmp.diff` - builtin fixes integrated

**Remaining patches in GCC 15 for x86_64**:
1. SSP nonshared linking (musl-specific)
2. posix_memalign namespace fix (musl-specific)
3. Static PIE support (musl-specific behavior)
4. libstdc++ cowpatch compatibility (build system)

**Plus 5 patches for other architectures**: J2 CPU (SuperH), M68k sqrt, 3× FDPIC patches (ARM/SuperH)

**Analysis**: The 4 x86_64 patches are fundamental musl/glibc differences unlikely to be upstreamed. GCC upstream prioritizes glibc compatibility.

### Source Code Migration

**GCC 15 uses C++ for compiler source**:
- `gcc/gcc.c` → `gcc/gcc.cc`
- Patches updated to target `.cc` files

### Better Standards Compliance

**GCC 15 improvements**:
- Better C23 support
- Improved C++23 support
- More aggressive optimization with `-O2` and `-O3`
- Better static analysis warnings

## Version Information

**Default configuration** (as of analysis):
- **Binutils**: 2.44
- **GCC**: 15.1.0 (with 9 musl-specific patches)
- **musl**: 1.2.5
- **GMP**: 6.3.0
- **MPC**: 1.3.1
- **MPFR**: 4.2.2
- **Linux headers**: 4.19.88-2

**Also supported**:
- GCC versions: 14.3.0, 14.2.0, 13.3.0, 12.4.0, 11.5.0, and older
- Multiple binutils versions
- Multiple musl versions back to 1.1.14

All versions are defined in the top-level Makefile and can be overridden via `config.mak`.

## Summary: Why Modern GCC is Better for musl

1. **Fewer patches needed** - More musl-aware upstream
2. **Better optimization** - Improved code generation
3. **Modern C/C++ standards** - C23, C++23 support
4. **Active maintenance** - Regular security updates
5. **Better testing** - More comprehensive test suites that include musl targets

The reduced patch count (9 vs 20+) demonstrates that GCC has become increasingly musl-aware over time, with many compatibility fixes integrated upstream. The remaining patches are either fundamental musl design differences (SSP, static-pie) or niche architecture-specific issues (FDPIC, J2, m68k).
