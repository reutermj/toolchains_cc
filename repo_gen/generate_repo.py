import csv
import os

def get_toolchains():
    with open('repo_gen/toolchains.csv', 'r') as csvfile:
        csvreader = csv.reader(csvfile)
        toolchains = [row for row in csvreader if any(row)]
    return toolchains

actions = [
    "ar_actions",
    "assembly_actions",
    "c_compile",
    "cpp_compile_actions",
    "link_actions",
    "link_data",
    "objcopy_embed_data",
    "strip",
]

visibility = "package(default_visibility = [\"//:__subpackages__\"])\n\n"

# ===============
# || Templates ||
# ===============
http_archive_tpl = """
http_archive(
    name = "{type}-{version}-{target_os}-{arch}",
    url = "https://github.com/reutermj/toolchains_cc/releases/download/{type}-{version}/{type}-{version}-{target_os}-{arch}.tar.xz",
    sha256 = "{sha}",
)
""".lstrip()

config_setting_tpl = """
config_setting(
    name = "{value}",
    flag_values = {{
        "//{dir}:{config}": "{value}",
    }},
)
""".lstrip()

alias_tpl = """
alias(
    name = "{action}",
    actual = select({{
        {conditions}
    }})
)
""".lstrip()

label_lookup_tpl = """
package(default_visibility = ["//:__subpackages__"])

{var_name} = {{
    {lookups}
}}
""".lstrip()

toolchain_bzl_tpl = """
load("@bazel_skylib//lib:dicts.bzl", "dicts")
{loads}

package(default_visibility = ["//:__subpackages__"])

{toolchain} = dicts.add(
    {dicts}
)
""".lstrip()

# ==================
# || MODULE.bazel ||
# ==================
def generate_module():
    # open the templates
    with open('repo_gen/MODULE.bazel.tpl', 'r') as file:
        module_tpl = file.read()

    toolchains = get_toolchains()
    
    # create the http_archive format replacements for the toolchain archives
    archives = {}
    for toolchain in toolchains:
        name = toolchain[0]
        version = toolchain[1]
        target_os = toolchain[2]
        arch = toolchain[3]
        sha = toolchain[4]
        key = f"{name}_{target_os}_{arch}"

        if key not in archives:
            archives[key] = ""
        http_archive = http_archive_tpl.format(
            type=name,
            version=version,
            target_os=target_os,
            arch=arch,
            sha=sha
        )
        archives[key] += http_archive

    # write out the module file
    module = module_tpl.format(**archives)
    with open('MODULE.bazel', 'w') as file:
        file.write(module)

# ========================
# || //toolchains/BUILD ||
# ========================
def generate_root_build():
    with open('repo_gen/BUILD.tpl', 'r') as file:
        build_tpl = file.read()
    toolchains = get_toolchains()

    versions = ""
    for toolchain in toolchains:
        config_setting = config_setting_tpl.format(
            value=toolchain[1],
            config="version",
            dir="toolchains"
        )

        versions += config_setting

    build = build_tpl.format(version_configs=versions)
    with open('toolchains/BUILD', 'w') as file:
        file.write(build)

# ==============================================
# || //toolchains/<toolchain>/<toolchain>.bzl ||
# ==============================================
def generate_tool_build():
    toolchains = get_toolchains()

    # aggregate all valid versions for a given toolchain
    versions_lookup = {}
    for toolchain in toolchains:
        name = toolchain[0]
        version = toolchain[1]

        if name not in versions_lookup:
            versions_lookup[name] = set()

        versions_lookup[name].add(version)
    
    # write out the aliases that picks out the version specified by the --@toolchains_cc//:version config
    for action in actions:
        for name, versions in versions_lookup.items():
            os.makedirs(f"toolchains/{name}", exist_ok=True)

            loads = ""
            dicts = ""
            for version in versions:
                dict_const = f"{name.upper()}_{version.replace('.', '_')}"
                loads += f"load(\":{version}.bzl\", \"{dict_const}\")\n"
                dicts += f"    {dict_const},\n"
            
            toolchain_bzl = toolchain_bzl_tpl.format(
                loads=loads.strip(),
                toolchain=name.upper(),
                dicts=dicts.strip()
            )
            with open(f"toolchains/{name}/{name}.bzl", 'w') as file:
                file.write(toolchain_bzl)

# ============================================
# || //toolchains/<toolchain>/<version>.bzl ||
# ============================================
def generate_tool_version_build():
    toolchains = get_toolchains()

    toolchain_to_version_to_os_arch = {}
    for toolchain in toolchains:
        name = toolchain[0]
        version = toolchain[1]
        target_os = toolchain[2]
        arch = toolchain[3]

        if name not in toolchain_to_version_to_os_arch:
            toolchain_to_version_to_os_arch[name] = {}

        version_to_os_arch = toolchain_to_version_to_os_arch[name]
        if version not in version_to_os_arch:
            version_to_os_arch[version] = []
        
        version_to_os_arch[version].append((target_os, arch))
    
    for name, version_to_os_arch in toolchain_to_version_to_os_arch.items():
        for version, targets in version_to_os_arch.items():
            os.makedirs(f"toolchains/{name}", exist_ok=True)

            lookups = ""
            for action in actions:
                for (target_os, arch) in targets:
                    lookups += f"    \"{name}-{version}-{target_os}-{arch}-{action}\": \"@{name}-{version}-{target_os}-{arch}//:{action}\",\n"
                
            version_name = version.replace('.', '_')
            lookup = label_lookup_tpl.format(
                var_name=f"{name.upper()}_{version_name}",
                lookups=lookups.strip()
            )

            with open(f"toolchains/{name}/{version}.bzl", 'w') as file:
                file.write(lookup)


if __name__ == "__main__":
    generate_module()
    generate_root_build()
    generate_tool_build()
    generate_tool_version_build()