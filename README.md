# toolchains_cc

[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)

Your one stop shop for default, hermetic c/c++ toolchains in Bazel!

This package:
* is easy to configure,
* supports linux, macos, and windows bazel builds,
* supports clang, gcc, and msvc compiler toolchains,
* supports x86_64 and arm64,
* has low overhead on CI runs, and
* enables remote caching to further speed up your development and CI.

## Dependency Management

This repository uses [Renovate](https://renovatebot.com/) to automatically keep dependencies up to date. Renovate:

- Monitors Bazel modules in `MODULE.bazel` files
- Updates GitHub Actions in workflows
- Groups related updates together (e.g., all Bazel rules)
- Automatically merges patch updates after CI passes
- Creates a dependency dashboard for tracking updates

Dependencies are updated weekly on Mondays. Critical security updates may be processed immediately.