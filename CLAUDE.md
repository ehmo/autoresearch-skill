# autoresearch

Autonomous codebase improvement using three independent teams.

## Structure

- `skills/autoresearch/SKILL.md` -- the protocol (team prompts, cycle management, all logic)
- `commands/autoresearch.md` -- slash command entry point
- `agents/codex.md` -- standalone protocol for Codex and other agents
- `install.sh` / `uninstall.sh` -- symlinks into ~/.claude/
- `sessions/` -- per-project session data (gitignored)

## How cycles run

1. Red team reads code, writes findings report (read-only)
2. Coordinator sanitizes findings (strips methodology, keeps what/where/impact)
3. Green team fixes issues one at a time with test verification
4. Refactor team simplifies recently-changed code
5. Coordinator verifies tests, logs results, starts next cycle

## Conventions

User-facing text should avoid AI writing patterns. Keep language direct and specific. No promotional phrasing, no filler.
