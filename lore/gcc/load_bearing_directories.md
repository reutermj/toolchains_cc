# Load-Bearing Directories in GCC Sysroot

## Problem Summary

A GCC toolchain that works when built directly fails with linker errors when packaged and extracted, even though all binaries and configuration files are identical.

## Symptoms

When attempting to compile even a simple "Hello World" program with the packaged toolchain:

```bash
bin/x86_64-linux-gnu-gcc -o main main.c -v -static --sysroot=x86_64-linux-gnu/sysroot/
```

The linker fails with:

```
ld: cannot find crt1.o: No such file or directory
ld: cannot find crti.o: No such file or directory
collect2: error: ld returned 1 exit status
```

### Diagnostic Clues

Comparing verbose output (`-v` flag) between working and failing toolchains reveals:

**Working toolchain** includes full paths to startup files:
```
collect2 ... x86_64-linux-gnu/sysroot/usr/lib/../lib64/crt1.o x86_64-linux-gnu/sysroot/usr/lib/../lib64/crti.o ...
```

**Failing toolchain** has bare filenames without paths:
```
collect2 ... crt1.o crti.o ...
```

Additionally, the `LIBRARY_PATH` environment variable (visible in `-v` output) is missing sysroot paths:

**Working:**
```
LIBRARY_PATH=.../x86_64-linux-gnu/lib/../lib64/:x86_64-linux-gnu/sysroot/lib/../lib64/:x86_64-linux-gnu/sysroot/usr/lib/../lib64/:.../:x86_64-linux-gnu/sysroot/lib/:x86_64-linux-gnu/sysroot/usr/lib/
```

**Failing:**
```
LIBRARY_PATH=.../x86_64-linux-gnu/lib/../lib64/:.../x86_64-linux-gnu/lib/
```

Note the missing sysroot paths in the failing version.

## Root Cause

GCC performs **runtime directory existence checks** to determine which library search paths to add to the linker command. The GCC driver checks for the existence of these directories in the sysroot:

1. `<sysroot>/lib`
2. `<sysroot>/usr/lib`

If these directories don't exist, GCC **silently omits** the corresponding library search paths from the linker command, even if the actual library files exist in subdirectories like `lib64` or `usr/lib64`.

### Why Files Exist But Aren't Found

The actual C runtime files (`crt1.o`, `crti.o`, etc.) are typically located in:
- `<sysroot>/usr/lib64/`

However, GCC's search path generation logic requires the parent directories to exist:
- `<sysroot>/lib/` must exist for `-Lx86_64-linux-gnu/sysroot/lib` and `-Lx86_64-linux-gnu/sysroot/lib/../lib64`
- `<sysroot>/usr/lib/` must exist for `-Lx86_64-linux-gnu/sysroot/usr/lib` and `-Lx86_64-linux-gnu/sysroot/usr/lib/../lib64`

### Why Packaging Loses These Directories

During the build process, these directories are created (see environment setup scripts), but they remain empty because:
- `lib/` is empty (all 64-bit libraries go to `lib64/`)
- `usr/lib/` is empty (all 64-bit libraries go to `usr/lib64/`)

When creating a tar archive:
```bash
tar cJf toolchain.tar.xz *
```

**Empty directories are not preserved by default** unless they contain at least one file. Upon extraction, these critical directories are missing, breaking GCC's path detection logic.

## The Fix

Create placeholder files in load-bearing empty directories before packaging:

```bash
# In the packaging script, before creating the tar archive:
touch <sysroot>/lib/.keep
touch <sysroot>/usr/lib/.keep
```

### Why This Works

1. The `.keep` files ensure the directories are included in the tar archive
2. Upon extraction, the directories are recreated with their placeholder files
3. GCC's directory existence checks pass
4. All library search paths are correctly added to linker commands
5. The placeholder files don't interfere with library searching or linking

### Implementation

Add this to your packaging script (e.g., `step-16_package_toolchain`):

```bash
#!/bin/bash
source ${SCRIPTS_DIR}/environment

# Create placeholder files to preserve load-bearing empty directories
# See: lore/gcc/load_bearing_empty_directories.md
touch "${OUTPUT_DIR}/x86_64-linux-gnu/sysroot/lib/.keep"
touch "${OUTPUT_DIR}/x86_64-linux-gnu/sysroot/usr/lib/.keep"

pushd "${OUTPUT_DIR}"
XZ_OPT=-e9 tar cJf "${ARTIFACTS_DIR}/toolchain.tar.xz" *
popd

# ... rest of packaging script
```

## Verification

After applying the fix, verify the toolchain works:

```bash
# Extract the packaged toolchain
tar xJf toolchain.tar.xz -C test-toolchain/

# Compile a test program
cd test-toolchain
bin/x86_64-linux-gnu-gcc -o test main.c -v -static --sysroot=x86_64-linux-gnu/sysroot/

# Check that the linker command includes full paths (not bare filenames)
# You should see: x86_64-linux-gnu/sysroot/usr/lib/../lib64/crt1.o
# Not just: crt1.o

# Run the test binary
./test
```

## Alternative Solutions

1. **Explicit directory creation in installation scripts:**
   ```bash
   mkdir -p x86_64-linux-gnu/sysroot/lib
   mkdir -p x86_64-linux-gnu/sysroot/usr/lib
   ```
   Less robust - requires users to know about this requirement.

2. **Use tar with explicit directory listing:**
   ```bash
   tar cJf toolchain.tar.xz --no-recursion <explicit-list-of-dirs-and-files>
   ```
   More complex to maintain.

3. **Document required directory structure:**
   Still requires manual intervention during extraction.

The placeholder file approach is recommended because it's self-contained, survives packaging/extraction, and provides a natural place to link to this documentation.

## Related Issues

- This issue can affect any GCC cross-compiler or relocatable toolchain
- Similar issues may exist with other compilers that perform runtime path detection
- The problem is architecture-independent (affects x86_64, ARM, etc.)

## References

- GCC driver source code: `gcc/gcc.cc` (search for sysroot path construction)
- GNU tar manual: Empty directories and archiving behavior
- Original issue: Comparison of `success.txt` vs `failure.txt` compilation logs
