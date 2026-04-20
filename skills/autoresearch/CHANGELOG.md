# Changelog

Semver: MAJOR for protocol-breaking changes, MINOR for additive features, PATCH for clarifications and fixes.

The current version is recorded in the YAML frontmatter of `SKILL.md`. Every new session stamps the version into its `session.md`; `resume` compares that stamp to the installed version.

## 2.0.0 — 2026-04-20

Added two new execution modes. The legacy loop is preserved as `sweep` mode.

### Added
- `narrow` mode. Gated by a quantifiable goal (metric, measurement command, baseline, target). Accepts one or more angles; refuses to start cycles until multi-angle inputs are priority-ranked. Works angles in order, re-measures after each cycle, and stops on target-met or exhaustion.
- `broad` mode. Strategist generates 3–5 hypotheses with required `obvious`/`bold`/`creative` categories. Each hypothesis runs on its own branch (`autoresearch/broad/<project>/h<N>`) from the base commit. After all tracks complete, a comparison document names a winner; losing branches are preserved.
- Per-mode Red team prompts scoped to the current angle or hypothesis.
- `Mode` field in `session.md`; resume reads it and dispatches accordingly.
- `version` argument prints the current skill version.
- `Skill version` field in `session.md`; resume compares it to the installed version and warns on MAJOR bumps / refuses to resume on downgrades.
- Eval rubric under `skills/autoresearch/eval/` (RUBRIC.md, GRADER.md, SCENARIOS.md) used to validate changes to the skill.

### Changed
- Session template expanded with `Skill version`, `Goal` (narrow only), `Angles` (narrow only), `Hypotheses` (broad only).
- Branch naming is mode-aware: sweep uses `autoresearch/improve[-N]`, narrow uses `autoresearch/narrow/<project>`, broad uses `autoresearch/broad/<project>/<h-id>` per track.
- `cycles/` layout in broad mode is per-track (`cycles/<hypothesis-id>/001/`).
- Refactor team skip is now config-only; the coordinator may not skip Refactor on judgment in any mode.

### Protocol-breaking
- Sessions created before 2.0.0 do not have a `Skill version` or `Mode` field. When resuming such a session, treat it as `sweep` mode and stamp the current version into `session.md` before continuing.

## 1.x — pre-2026-04

Original sweep-only loop: Red → Green → Refactor cycles with no goal gate, no hypothesis divergence, no per-session mode. Preserved as `sweep` mode in 2.0.0.
