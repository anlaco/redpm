Pseudocode: create `git-client` (Sprint 1 — Task 1.3)

Objective
- Encapsulate all `git` interactions behind a `git-client` context so the rest
  of the codebase never calls `call`/`call/shell` directly.

Pseudocode (outside source)
1. Public interface for `git-client`:
   - `git-available?` → logic!
   - `clone-repo url path /shallow` → logic! (true on success)
   - `pull-repo path` → string! (stdout) or none on failure
   - `checkout-version path ref` → logic!
   - `get-current-sha path` → string! (SHA) or none
   - `repo-has-changes? path` → logic!
2. Implement `git-client` in `src/git-client.red`. Use `call/output` or
   `call/wait/shell` internally, parse stdout, return idiomatic Red types.
3. Replace direct `git` shell calls in `redpm.red` with the new API.
4. Add `tests/git-client-smoke.red` with minimal assertions:
   - `git-available?` must be true
   - `clone-repo` into a temp dir (small public repo) and then `repo-has-changes?`
   - cleanup after test

Acceptance criteria
- `redpm.red` no longer contains raw `git ...` shell commands.
- `git-client` exposes the listed functions and returns documented types.
- Smoke test for `git-client` passes locally.

Risks & mitigations
- Network required for clone tests: make the smoke test tolerant (clean
  up on failure and report readable error).
- Keep parsing of `git` output conservative (look for exact markers like
  "Already up to date" or `rev-parse` output).
