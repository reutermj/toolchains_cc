# Commit Message Guidelines

This runbook describes the commit message format for the toolchains_cc project.

## Philosophy

Commit messages should focus on **why** and **what**, not **how**. The diff shows the "how"—your message should provide the context and reasoning that the diff cannot convey.

## Format

Commits use markdown formatting and follow this structure:

```
<type>: <subject>

## Problem

<description of what problem this solves or what need this addresses>

## Context

<background information, design decisions, or important details>

### <optional subsection>

<additional context points as needed>

## <optional additional sections>

<other sections as appropriate: Test Plan, Breaking Changes, etc.>

<optional footer: co-authors, issue references, etc.>
```

## Required Sections

### 1. Subject Line

**Format**: `<type>: <subject>`

**Types** (enforced by commitlint):
- `feat`: New feature or capability
- `fix`: Bug fix
- `docs`: Documentation changes
- `chore`: Maintenance, dependencies, tooling

**Subject Guidelines**:
- Use imperative mood ("add feature" not "added feature")
- Don't capitalize first letter after colon
- No period at the end
- Keep under 72 characters if possible

**Examples**:
- `feat: add support for musl libc 1.2.5`
- `fix: resolve linker errors with glibc 2.42`
- `docs: add runbook structure for token-efficient documentation`
- `chore: clean up GCC build scripts and documentation`

### 2. Problem Section

Explain **what problem** this commit solves or **what need** it addresses. This is the "why are we making this change?" section.

**Good examples**:
```markdown
## Problem

Claude Code loads CLAUDE.md on every conversation, consuming tokens even for
rarely-used content like detailed procedures. As documentation grows, this
wastes tokens and slows down conversations that don't need the detailed context.
```

```markdown
## Problem

Users need to build C/C++ code against musl libc for static linking, but the
toolchain currently only supports glibc targets.
```

**Bad examples**:
```markdown
## Problem

This commit adds a new file.
```
*(This describes "what" you did, not "why")*

```markdown
## Problem

The code was wrong.
```
*(Too vague—what was wrong and why does it matter?)*

### 3. Context Section

Provide **background information** and **design decisions** that help reviewers understand the approach. This section can have multiple subsections for different context points.

**Good examples**:
```markdown
## Context

This implements a two-tier documentation structure:
- CLAUDE.md contains frequently-used quick reference (always loaded)
- docs/runbooks/ contains detailed procedures (loaded on-demand)

### Token Efficiency

The previous inline procedure consumed ~200 tokens per conversation.
The new reference-based approach uses ~10 tokens, with the full runbook
(~1,100 tokens) loaded only when explicitly needed.

### Pattern for Future Documentation

The Documentation Structure section in CLAUDE.md establishes this pattern
for all future runbooks, ensuring the approach is discoverable.
```

```markdown
## Context

Musl libc produces fully static binaries without external dependencies, making
it ideal for containerized deployments and embedded systems.

### Implementation Approach

Rather than modifying the existing glibc toolchain configuration, this adds
musl as a separate target triple (x86_64-linux-musl) to maintain clean
separation and avoid cross-contamination of libc implementations.

### Version Selection

Starting with musl 1.2.5 (latest stable) for the initial implementation.
Earlier versions can be added if needed based on user requirements.
```

## Optional Sections

Add additional sections as appropriate for your commit:

### Test Plan

```markdown
## Test Plan

- [x] Verify all existing glibc configurations still build
- [x] Build hello world with musl target
- [x] Confirm static linking with `ldd` (should show "not a dynamic executable")
- [x] Run in alpine container to verify no glibc dependencies
```

### Breaking Changes

```markdown
## Breaking Changes

The `toolchains_cc_libc` environment variable has been renamed to
`toolchains_cc_libc_version` to better reflect that it specifies a version
number, not a libc type (which is inferred from the target triple).

Users must update their build commands:
- Old: `--repo_env=toolchains_cc_libc=2.39`
- New: `--repo_env=toolchains_cc_libc_version=2.39`
```

### Migration Guide

```markdown
## Migration Guide

For users currently using custom toolchain configurations:

1. Update environment variable names in `.bazelrc` files
2. Update CI workflow files to use new variable names
3. No changes needed to BUILD files or source code
```

### Related Changes

```markdown
## Related Changes

This is part of a larger effort to support multiple C libraries:
- #45: Add musl support (this PR)
- #52: Add support for different glibc versions
- #60: Planned uclibc support
```

## Full Example

```
feat: add support for musl libc 1.2.5

## Problem

Users need to build C/C++ code against musl libc for static linking and
containerized deployments, but the toolchain currently only supports
glibc targets. Static binaries are essential for minimal container images
and environments where glibc may not be available.

## Context

Musl libc produces fully static binaries without external dependencies,
making it ideal for Alpine Linux containers and embedded systems.

### Implementation Approach

Rather than modifying the existing glibc toolchain configuration, this adds
musl as a separate target triple (x86_64-linux-musl) to maintain clean
separation and avoid cross-contamination between libc implementations.

The two-phase repository rule design (eager declaration + lazy download)
works seamlessly with musl targets—no architectural changes needed.

### Version Selection

Starting with musl 1.2.5 (latest stable as of 2024-11) for the initial
implementation. Earlier versions can be added based on user requirements.

## Test Plan

- [x] Build and test with musl 1.2.5 target
- [x] Verify static linking with `ldd` (should show "not a dynamic executable")
- [x] Run in Alpine container to verify no glibc dependencies
- [x] Confirm existing glibc configurations still work
- [x] Add musl to CI test matrix

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## What to Avoid

❌ **Don't repeat the diff**: The code changes are visible in the diff

```markdown
## Problem

Changed line 42 from `foo` to `bar`.
```

❌ **Don't write implementation details**: Save those for code comments

```markdown
## Context

This uses a for loop to iterate over the list and calls the transform
function on each element, then appends to a new list.
```

❌ **Don't be vague**:

```markdown
## Problem

Things weren't working right.

## Context

Fixed it.
```

✅ **Do explain reasoning and impact**:

```markdown
## Problem

Bazel was downloading toolchain binaries even for Python-only builds,
adding 5+ minutes to CI runs that don't need C/C++ compilation.

## Context

The lazy download design allows Bazel to register toolchains without
downloading binaries until actual compilation occurs. This is critical
for polyglot repositories where different builds have different needs.
```

## Tips for Writing Good Commit Messages

1. **Write for future maintainers**: Someone (including future you) will read this commit in 6 months trying to understand why a decision was made

2. **Answer the question "why this approach?"**: If there were alternative solutions, briefly explain why you chose this one

3. **Include relevant context**: Benchmark numbers, error messages, compatibility requirements, or architectural constraints

4. **Link to related issues/PRs**: Use `#123` notation for GitHub integration

5. **Use markdown formatting**: Headers, lists, code blocks, and emphasis make messages scannable

6. **Be concise but complete**: Every sentence should add value, but don't leave out important context

## Commit Message Checklist

Before committing, verify:

- [ ] Subject line follows `<type>: <subject>` format
- [ ] Problem section explains **why** this change is needed
- [ ] Context section provides **design decisions** and **background**
- [ ] Subsections used when multiple context points exist
- [ ] Focus is on "why" and "what", not "how"
- [ ] Markdown formatting used for readability
- [ ] Message will make sense to someone 6 months from now
- [ ] No implementation details that belong in code comments

## Tools

The repository uses commitlint to enforce the subject line format. See [.commitlintrc.js](../../.commitlintrc.js) for the configuration.
