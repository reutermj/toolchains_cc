# toolchains_cc

## Runbooks

Runbooks are detaild procedures for use in a specific context.
**When a runbook's context occurs, YOU MUST ALWAYS read the runbook BEFORE taking any action.**

- **BEFORE creating any commit, YOU MUST read**: [docs/runbooks/commit-message-guidelines.md](docs/runbooks/commit-message-guidelines.md)
- **BEFORE adding new toolchain configurations, YOU MUST read**: [docs/runbooks/add-toolchain-configuration.md](docs/runbooks/add-toolchain-configuration.md)
- **BEFORE creating or modifying GitHub Actions workflows, YOU MUST read**: [docs/runbooks/github-actions-workflows.md](docs/runbooks/github-actions-workflows.md)

## Building

Use the `./bazel` wrapper script instead of `bazel`

```bash
# Build everything with default toolchain (gcc 15.2.0, glibc 2.28, x86_64-linux-gnu)
./bazel build //...

# Build with specific toolchain configuration
./bazel build \
  --repo_env=toolchains_cc_target=x86_64-linux-gnu \
  --repo_env=toolchains_cc_libc_version=2.39 \
  --repo_env=toolchains_cc_compiler_version=15.2.0 \
  //...

# Build tests
./bazel build //tests/...
```

## Testing
```bash
# Run all tests
./bazel test //...

# Run specific test
./bazel test //tests/hello_world:hello
./bazel test //tests/hello_world:hello++
```

## Linting
```bash
# Check Bazel file formatting
./bazel run :buildifier.check

# Auto-fix Bazel file formatting
./bazel run :buildifier.fix
```

## Comment Philosophy

**ALWAYS follow these guidelines when writing or modifying code comments.**

### Core Principles

1. **Inline comments answer "why?"** - Why this choice? Why this workaround? Why this optimization?
2. **Doc comments answer "what?"** - What does this function/class do? What's the API?
3. **Code answers "how?"** - Through clear naming, good factoring, and self-documenting structure
4. **Commit messages provide rationale** - Longer explanations of design decisions
5. **Links are valuable** - Point to issues, bug trackers, docs, RFCs, etc.
6. **TODOs go in beads** - Not in source code comments

### Good Reasons for Inline Comments

- Workarounds for bugs in dependencies
- Non-obvious constraints from external systems
- Performance optimizations that might seem unusual
- Design tradeoffs that aren't obvious from the code

### Links and References

**Link format:**
- **Current repo GitHub issues:** Use short form `#1234`
- **External issues/bugs:** Use full URL `https://github.com/org/repo/issues/1234`
- **Current repo docs:** Use relative path from repo root `docs/architecture.md`
- **External docs:** Use full URL `https://sourceware.org/glibc/wiki/ABICompatibility`
- **Beads issues:** Use full ID `toolchains_cc-di2`

**Combining references:** When helpful, include both a beads reference (for agent/internal tracking) and an external link (for human readers):

```c++
// Prevent RSS bloat in long-running processes (toolchains_cc-di2)
// https://sourceware.org/bugzilla/show_bug.cgi?id=11261
malloc_trim(0);
```

### Examples

**Good - Dependency workaround:**
```python
# Bazel requires explicit include paths for cross-compilation
# See: https://github.com/bazelbuild/bazel/issues/12345
builtin_include_dirs = [...]
```

**Good - Platform-specific workaround:**
```c++
#ifdef __GLIBC__
// Prevent RSS bloat in long-running processes (bd-456)
// https://sourceware.org/bugzilla/show_bug.cgi?id=11261
malloc_trim(0);
#endif
```

**Good - Performance optimization:**
```python
# Cache lookups because toolchain resolution is expensive
# (involves filesystem scanning and version parsing)
if target_triple in _cache:
    return _cache[target_triple]
```

**Bad - Explains "what?" (obvious):**
```c++
// Calculate the sum of two numbers
int add(int a, int b) { return a + b; }
```

**Bad - TODO in code (use beads instead):**
```c++
// TODO: Add ARM64 support  ❌
```

### Before Adding "How?" Comments

Try these alternatives first:
1. Rename variables/functions to be more descriptive
2. Extract complex expressions into named variables
3. Break complex logic into smaller, well-named functions

If code truly requires a "how?" explanation despite refactoring attempts, add the comment. Don't let the code remain obscure.

## Issue Tracking with bd (beads)

**IMPORTANT**: This project uses **bd (beads)** for ALL issue tracking. Do NOT use markdown TODOs, task lists, or other tracking methods.

### Why bd?

- Dependency-aware: Track blockers and relationships between issues
- Git-friendly: Auto-syncs to JSONL for version control
- Agent-optimized: JSON output, ready work detection, discovered-from links
- Prevents duplicate tracking systems and confusion

### Quick Start

**Check for ready work:**
```bash
bd ready --json
```

**Create new issues:**
```bash
bd create "Issue title" -t bug|feature|task -p 0-4 --json
bd create "Issue title" -p 1 --deps discovered-from:bd-123 --json
```

**Claim and update:**
```bash
bd update bd-42 --status in_progress --json
bd update bd-42 --priority 1 --json
```

**Complete work:**
```bash
bd close bd-42 --reason "Completed" --json
```

### Issue Types

- `bug` - Something broken
- `feature` - New functionality
- `task` - Work item (tests, docs, refactoring)
- `epic` - Large feature with subtasks
- `chore` - Maintenance (dependencies, tooling)

### Priorities

- `0` - Critical (security, data loss, broken builds)
- `1` - High (major features, important bugs)
- `2` - Medium (default, nice-to-have)
- `3` - Low (polish, optimization)
- `4` - Backlog (future ideas)

### Workflow for AI Agents

1. **Check ready work**: `bd ready` shows unblocked issues
2. **Claim your task**: `bd update <id> --status in_progress`
3. **Work on it**: Implement, test, document
4. **Discover new work?** Create linked issue:
   - `bd create "Found bug" -p 1 --deps discovered-from:<parent-id>`
5. **Complete**: `bd close <id> --reason "Done"`
6. **Commit together**: Always commit the `.beads/issues.jsonl` file together with the code changes so issue state stays in sync with code state

### Auto-Sync

bd automatically syncs with git:
- Exports to `.beads/issues.jsonl` after changes (5s debounce)
- Imports from JSONL when newer (e.g., after `git pull`)
- No manual export/import needed!

### MCP Server (Recommended)

If using Claude or MCP-compatible clients, install the beads MCP server:

```bash
pip install beads-mcp
```

Add to MCP config (e.g., `~/.config/claude/config.json`):
```json
{
  "beads": {
    "command": "beads-mcp",
    "args": []
  }
}
```

Then use `mcp__beads__*` functions instead of CLI commands.

### Managing AI-Generated Planning Documents

AI assistants often create planning and design documents during development:
- PLAN.md, IMPLEMENTATION.md, ARCHITECTURE.md
- DESIGN.md, CODEBASE_SUMMARY.md, INTEGRATION_PLAN.md
- TESTING_GUIDE.md, TECHNICAL_DESIGN.md, and similar files

**Best Practice: Use a dedicated directory for these ephemeral files**

**Recommended approach:**
- Create a `history/` directory in the project root
- Store ALL AI-generated planning/design docs in `history/`
- Keep the repository root clean and focused on permanent project files
- Only access `history/` when explicitly asked to review past planning

**Example .gitignore entry (optional):**
```
# AI planning documents (ephemeral)
history/
```

**Benefits:**
- ✅ Clean repository root
- ✅ Clear separation between ephemeral and permanent documentation
- ✅ Easy to exclude from version control if desired
- ✅ Preserves planning history for archeological research
- ✅ Reduces noise when browsing the project

### Important Rules

- ✅ Use bd for ALL task tracking
- ✅ Always use `--json` flag for programmatic use
- ✅ Link discovered work with `discovered-from` dependencies
- ✅ Check `bd ready` before asking "what should I work on?"
- ✅ Store AI planning docs in `history/` directory
- ❌ Do NOT create markdown TODO lists
- ❌ Do NOT use external issue trackers
- ❌ Do NOT duplicate tracking systems
- ❌ Do NOT clutter repo root with planning documents
