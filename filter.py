import re

header = """
#/bin/bash -e
export PATH=/tmp/work/.build/x86_64-linux-musl/buildtools/bin:$PATH

""".lstrip()


def check_entering(line, output):
    """Check if line is an 'Entering' directive and emit cd command if so.
    Returns True if line was handled, False otherwise."""
    if "[DEBUG]" in line and "Entering '" in line:
        match = re.search(r"Entering '([^']+)'", line)
        if match:
            directory = match.group(1)
            # Skip non-path entries like 'evaluate_cflags' or 'multilib'
            if directory.startswith('/'):
                output.write(f"mkdir -p '{directory}'\n")
                output.write(f"cd '{directory}'\n")
        return True
    return False


def process_initial_lines(lines):
    with open("step-01_initial-lines", "w") as output:
        output.write(header)
        output.write("ct-ng defconfig\n\n")
        for i, line in enumerate(lines):
            if "Preparing working directories" in line:
                return lines[i:]

            if check_entering(line, output):
                continue

            if '==> Executing:' in line:
                line = line.replace("[DEBUG]", "")
                line = line.replace('==> Executing:', '')
                line = line.strip()
                output.write(f"{line}\n")

    assert False


def process_working_directory(lines):
    with open("step-02_working-directory", "w") as output:
        output.write(header)
        for i, line in enumerate(lines):
            if "Making build system tools available" in line:
                return lines[i:]

            if check_entering(line, output):
                continue

            if '==> Executing:' in line:
                line = line.replace("[DEBUG]", "")
                line = line.replace('==> Executing:', '')
                line = line.strip()
                output.write(f"{line}\n")

    assert False


def process_build_system_tools(lines):
    with open("step-03_build-system-tools", "w") as output:
        output.write(header)
        i = 0
        while i < len(lines):
            line = lines[i]
            if "Checking that we can run gcc -v" in line:
                return lines[i:]

            i += 1

            if check_entering(line, output):
                continue

            if "' -> '" in line:
                parts1 = line.split()
                parts2 = lines[i].split()
                i += 1
                target = parts1[3]
                if parts2[3] == "'chmod'":
                    link = parts2[5]
                elif parts2[3] == "'cp'":
                    # appears to be redundant with previous chmod conditions
                    continue
                else:
                    assert False
                output.write(f"'ln' '-s' {target} {link}\n")

    assert False


def skipping_gcc_check(lines):
    for i, line in enumerate(lines):
        if "Retrieving needed toolchain components' tarballs" in line:
            return lines[i:]

    assert False


def download_sources(lines):
    # maps package name (e.g., "linux-4.20.17") to full tarball path
    tarball_cache = {}
    with open("step-04_download_sources", "w") as output:
        output.write(header)
        for i, line in enumerate(lines):
            if "Extracting and patching toolchain components" in line:
                return lines[i:], tarball_cache

            if check_entering(line, output):
                continue

            if '==> Executing:' in line:
                line = line.replace("[DEBUG]", "")
                line = line.replace('==> Executing:', '')
                line = line.replace('.tmp-dl', '')
                # Remove -nc flag so wget overwrites partial/failed downloads
                line = line.replace("'-nc'", "")
                line = line.strip()
                output.write(f"{line} || /bin/true\n")

                # Extract tarball path and cache it by package name
                # e.g., '/tmp/work/.build/tarballs/linux-4.20.17.tar.xz'
                if '/tarballs/' in line:
                    match = re.search(
                        r"'/tmp/work/.build/tarballs/([^']+)'", line)
                    if match:
                        tarball_filename = match.group(1)
                        # Extract package name by removing .tar.* extension
                        package_name = re.sub(
                            r'\.tar\.(xz|gz|bz2)$', '', tarball_filename)
                        tarball_path = f"/tmp/work/.build/tarballs/{tarball_filename}"
                        tarball_cache[package_name] = tarball_path

    assert False


def extract_sources(lines, tarball_cache):
    current_package = None
    with open("step-05_extract_sources", "w") as output:
        output.write(header)
        for i, line in enumerate(lines):
            if "Installing ncurses for build" in line:
                return lines[i:]

            if check_entering(line, output):
                continue

            if '==> Executing:' in line:
                line = line.replace("[DEBUG]", "")
                line = line.replace('==> Executing:', '')
                line = line.strip()

                # Detect package name from 'rm' '-f' '/tmp/work/.build/src/.linux-4.20.17.*'
                if "'rm' '-f' '/tmp/work/.build/src/." in line:
                    match = re.search(
                        r"'/tmp/work/.build/src/\.(.+)\.\*'", line)
                    if match:
                        current_package = match.group(1)

                # Replace stdin tar with tarball-based tar
                if "'tar' 'x' '-v' '-f' '-'" in line and current_package:
                    tarball_path = tarball_cache.get(current_package)
                    if tarball_path:
                        line = f"'tar' 'xvf' '{tarball_path}' '-C' '/tmp/work/.build/src'"

                output.write(f"{line}\n")

    assert False


def parse_build(lines, num):
    with open(f"step-06.{num}_build", "w") as output:
        output.write(header)
        for i, line in enumerate(lines):
            if i == 0:
                end_text = line.strip()
                output.write(f"# {end_text}\n")
                continue

            if end_text in line:
                return lines[i+2:]

            if check_entering(line, output):
                continue

            if '==> Executing:' in line:
                line = line.replace("[DEBUG]", "")
                line = line.replace('==> Executing:', '')
                line = line.strip()
                output.write(f"{line}\n")

    assert False


def finalize_directory(lines):
    with open("step-07_finalize-directory", "w") as output:
        output.write(header)
        for i, line in enumerate(lines):

            if check_entering(line, output):
                continue

            if '==> Executing:' in line:
                line = line.replace("[DEBUG]", "")
                line = line.replace('==> Executing:', '')
                line = line.strip()
                output.write(f"{line}\n")


def write_remainig(lines):
    with open("remaining", "w") as output:
        for line in lines:
            output.write(f"{line}")


with open('build.log', 'r') as input:
    lines = input.readlines()

lines = process_initial_lines(lines)
lines = process_working_directory(lines)
lines = process_build_system_tools(lines)
lines = skipping_gcc_check(lines)
lines, tarball_cache = download_sources(lines)
lines = extract_sources(lines, tarball_cache)
for i in range(17):
    lines = parse_build(lines, i)
finalize_directory(lines)
