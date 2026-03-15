# CLAUDE.md — redpm

AI assistant guide for the **redpm** (Red Package Manager) codebase.

---

## Project Overview

**redpm** is a package manager for the [Red programming language](https://www.red-lang.org/). It manages dependencies from Git repositories. Current version: **0.1.1** (MVP/Sprint 1 complete).

- Language: Red
- Build: GNU Make + `./redc` (Red compiler)
- No CI/CD yet (`.github/` is gitignored, planned for later)
- Engineering docs are in Spanish under `docs/`

---

## Repository Structure

```
redpm/
├── redpm.red            # Entry point — CLI dispatcher
├── deps.red             # Example dependency file (user-facing format)
├── Makefile             # Build automation
├── README.md            # User-facing documentation
├── ROADMAP.md           # 7-phase development roadmap
├── src/
│   ├── package.red      # Package ADT (constructor, accessors, predicates)
│   ├── logger.red       # Colored logging with verbosity levels
│   ├── git-client.red   # Wrapper over git CLI (clone, pull, sha)
│   ├── registry.red     # Read/write deps.red and deps.lock
│   ├── filesystem.red   # Cross-platform directory helpers
│   ├── validator.red    # Input validation — the "barricade"
│   └── manager.red      # Business logic orchestrator
├── tests/
│   ├── logger-smoke.red
│   ├── git-client-smoke.red
│   ├── filesystem-smoke.red
│   ├── package-smoke.red
│   ├── registry-smoke.red
│   └── manager-smoke.red
└── docs/                # Engineering documentation (Spanish)
    ├── 01-definicion-del-problema.md
    ├── 02-plan-maestro.md
    ├── 03-arquitectura.md
    ├── 04-convenciones-de-codigo.md
    ├── 05-guia-de-calidad.md
    ├── pseudocode-logger.md
    └── pseudocode-git-client.md
```

---

## Build

**Prerequisite:** The Red compiler `./redc` must be present and executable in the repo root. It is not included — download it from https://www.red-lang.org/p/download.html.

```bash
make build    # Compiles redpm.red → bin/redpm
make clean    # Removes bin/ and libRedRT* artifacts
make help     # Shows available targets
```

The compile command is: `./redc -r -o redpm redpm.red`

---

## Running

```bash
./bin/redpm init              # Create a deps.red template
./bin/redpm install           # Clone all deps listed in deps.red
./bin/redpm update            # git pull all installed packages
./bin/redpm remove <name>     # Delete a specific package directory
./bin/redpm list              # Show dependency status
./bin/redpm help              # Show usage
```

Packages are installed to `deps/<PackageName>/`.

### `deps.red` format

```red
[
    ;-- Format: PackageName "https://github.com/user/repo"
    Red-Utils "https://github.com/ANLACO/Red-Utils"
    MyLib     "https://github.com/org/lib"
]
```

---

## Architecture

### Module inclusion order (in `redpm.red`)

```
package → logger → git-client → registry → filesystem → validator → manager
```

`manager.red` is the top-level orchestrator and depends on all other modules.

### Module responsibilities

| Module | Role |
|--------|------|
| `package` | ADT for packages: constructor, accessors (`get-name`, `get-url`, etc.), predicates (`installed?`) |
| `logger` | ANSI-colored output: `log-ok`, `log-error`, `log-info`, `log-warn`, `log-debug` |
| `git-client` | Wraps git CLI: `clone-repo`, `pull-repo`, `get-sha`, `git-available?` |
| `registry` | Reads/writes `deps.red` and `deps.lock`; returns `block!` of package objects |
| `filesystem` | `ensure-dir`, `remove-dir`, `dir-exists?`, `list-subdirs` |
| `validator` | Barricade pattern: `valid-url?`, `valid-package-name?`, `valid-version-spec?`, `sanitize-path` |
| `manager` | Orchestrates: `init`, `install-single`, `install-all`, `update-all`, `remove-by-name`, `list` |

### Key design patterns

1. **`context` for modules** — all state and functions encapsulated, no globals
2. **ADT pattern** — `package` context provides constructor + typed accessors
3. **Barricade pattern** — `validator` sanitizes all external input before it reaches business logic
4. **Return values for errors** — functions return `true`/`false` or a value; use `attempt` for try-catch; never fail silently
5. **`#include`** — Red's compile-time file inclusion (not dynamic loading)

---

## Testing

Tests are smoke tests run manually with the Red interpreter:

```bash
red tests/logger-smoke.red
red tests/package-smoke.red
red tests/registry-smoke.red
red tests/filesystem-smoke.red
red tests/git-client-smoke.red   # Clones a real repo — requires internet
red tests/manager-smoke.red
```

Each test exits with code 0 on success, 1 on failure. There is no test runner; run tests individually. The `git-client-smoke` test performs a real network clone of `https://github.com/ANLACO/Red-Utils`.

**Rule:** Every commit must leave the smoke tests passing.

---

## Code Conventions

Full details in `docs/04-convenciones-de-codigo.md`. Summary:

### Naming

- **Functions:** `verb-noun` in kebab-case — e.g., `install-package`, `load-config`
- **Predicates:** end in `?` — e.g., `installed?`, `valid-url?`, `dir-exists?`
- **Variables:** `noun` or `adjective-noun` — e.g., `deps-dir`, `package-list`
- **Contexts:** singular noun — e.g., `logger`, `registry`, `validator`
- Avoid abbreviations; no single-letter names except in trivial loops

### Use native Red types

```red
;-- Use url! not string! for URLs
url: https://github.com/ANLACO/Red-Utils

;-- Use file! not string! for paths
path: %deps/Red-Utils/

;-- Use word! not string! for status
status: 'installed    ;-- 'missing | 'installed | 'outdated
```

### File structure

Every `.red` file starts with a Red header block:

```red
Red [
    Title:   "Descriptive module name"
    Author:  "ANLACO"
    File:    %src/module-name.red
    Version: 0.1.1
    Purpose: {One or two lines explaining what this module does and why.}
]
```

### Comments

Comments explain **why**, not **what**. The code explains what it does; comments explain decisions:

```red
;-- Use depth 1 to avoid downloading the entire history — saves bandwidth.
cmd: rejoin ["git clone --depth 1 " url " " path]
```

Section separators inside long contexts:

```red
;-------------------------------------------------------
;-- SECTION: Public interface
;-------------------------------------------------------
```

### Formatting

- Indentation: **4 spaces** (no tabs)
- Max line length: **80 characters**
- Align object fields for readability
- One blank line between functions; max two consecutive blank lines

### Error handling

Always wrap risky I/O in `attempt`; always log on failure; always `return none` or `false` on failure — never silently continue:

```red
result: attempt [read url]
unless result [
    logger/log-error rejoin ["Could not download from " url]
    return none
]
```

### Prohibited practices

| Prohibited | Reason |
|------------|--------|
| `probe` in production code | Debug-only; use `logger/log-debug` |
| Global variables | Everything inside `context` |
| `call/shell` without validated input | Command injection risk |
| Commented-out dead code | Delete it; git has history |
| Functions over 50 lines | Split into named subfunctions |
| More than 3 nesting levels | Extract or use early return |

---

## Commit Messages

Format: `<type>: <short description>`

Allowed types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`

```
feat: add version tag support in deps.red

fix: remove debug probe from cmd-remove

refactor: complete Sprint 1 — modular architecture with context

docs: update conventions for pseudocode workflow
```

---

## Development Methodology (PPP)

The project uses **PPP (Pseudocódigo → Prueba → Programación)**:

1. Write pseudocode for non-trivial functions (>10 lines or with branching logic)
2. Review the pseudocode
3. Implement the code
4. Discard the pseudocode — it does not go in the source file

Pseudocode for existing modules is in `docs/pseudocode-*.md` as design artifacts.

---

## Known Issues & Roadmap

- **Windows:** `.git` folder removal fails due to read-only file permissions — tracked in ROADMAP.md
- **Cross-platform support:** `filesystem.red` is Unix-focused; Windows support planned for v0.2.0
- **Lockfile:** `deps.lock` has a basic placeholder implementation; full support in v0.3.0
- **Transitive dependencies, registry, caching:** Planned for v0.4.0+

See `ROADMAP.md` for the full 7-phase plan.

---

## Important Paths & Configuration

| Item | Value |
|------|-------|
| Package install dir | `deps/` (relative to working directory) |
| Dependency file | `deps.red` |
| Lockfile | `deps.lock` |
| Compiled binary | `bin/redpm` |
| Compiler | `./redc` (must be downloaded separately) |

These defaults are set as public fields in `registry` context (`registry/deps-dir`, `registry/deps-file`, `registry/lock-file`) and can be overridden programmatically.
