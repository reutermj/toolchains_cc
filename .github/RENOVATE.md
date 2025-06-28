# Renovate Configuration

This repository uses [Renovate](https://renovatebot.com/) to automatically manage dependency updates.

## Configuration Overview

The Renovate configuration is defined in [`.github/renovate.json5`](./renovate.json5) and includes:

### Update Schedule
- **When**: Weekly on Mondays before 4am UTC
- **Critical updates**: Processed immediately for security issues

### Dependency Grouping
- **Bazel rules**: All `rules_*`, `bazel_skylib`, and `platforms` dependencies are grouped together
- **GitHub Actions**: All workflow dependencies are grouped together

### Auto-merge Settings
- **Patch updates**: Automatically merged after CI passes
- **Minor/Major updates**: Require manual review
- **Security updates**: Follow standard process

### Supported Dependencies

1. **Bazel Modules** (`MODULE.bazel` files)
   - `rules_cc`
   - `bazel_skylib` 
   - `platforms`

2. **GitHub Actions** (`.github/workflows/*.yml`)
   - `actions/checkout`
   - Other action dependencies

3. **Custom Regex Patterns**
   - LLVM versions in shell scripts
   - LLVM versions in download URLs

## Dashboard

Renovate creates a dependency dashboard in the Issues tab to track:
- Pending updates
- Failed updates
- Configuration errors

## Customization

To modify the configuration:

1. Edit `.github/renovate.json5`
2. Test changes using [Renovate's config validator](https://app.renovatebot.com/config)
3. Commit changes to enable new behavior

## Troubleshooting

- **Updates not appearing**: Check the dependency dashboard issue
- **Auto-merge not working**: Verify CI status checks are passing
- **Version not detected**: May need custom regex in `regexManagers`