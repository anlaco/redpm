Pseudocode: create `logger` (Sprint 1 — Task 1.2)

Objective
- Extract the output helper functions (`print-ok`, `print-err`, `print-info`, `print-warn`) and the color constants into a `context` named `logger`.

Pseudocode (outside the source)
1. Design the public interface of `logger`:
   - `log-ok msg`
   - `log-error msg`
   - `log-info msg`
   - `log-warn msg`
   - `log-debug msg` (only if `--verbose`)
   - Export color constants: `green`, `red`, `yellow`, `cyan`, `reset` (for occasional use)
2. Implement `logger` as a `context` in `src/logger.red`.
3. Replace all references to `print-*` in `redpm.red` with `logger/log-*`.
4. Update `#include` to add `#include %src/logger.red`.
5. Add `tests/logger-smoke.red` that verifies the presence of functions and that calling them does not fail.

Acceptance criteria
- `redpm.red` builds and `help` runs without errors.
- `tests/logger-smoke.red` and `tests/package-smoke.red` pass.
- No definitions of `print-ok/err/info/warn` remain in the source.

Review (self-evaluation)
- Scope: minimal and backward-compatible; does not change output formatting.
- Risks: external callers that used `green`/`reset` must now use `logger/green` or `logger/log-*`.
- Mitigation: color constants are exported as public symbols in `logger`.

Implementation notes
- `log-debug` will respect the presence of `-v`/`--verbose` in `system/options/args`.
- Non-obvious decisions are documented as comments in `src/logger.red`.

Reviewed by: GitHub Copilot (auto-review) — approved for implementation.
