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

## Skimmable Code Rules

Default to code that is obvious on a fast read.

- Keep code short. Prefer fewer lines and fewer moving parts.
- Remove any change that is not strictly required.
- Minimize state. Narrow types, reduce arguments, and do not carry optional values unless they are truly optional.
- Prefer explicit tagged state over loose bags of flags. Use discriminated unions, enums with payloads, or equivalent typed variants.
- Exhaustively handle variant types. Fail fast on unknown cases.
- Trust the types. Do not add defensive code for states the types already rule out.
- Assert required inputs and loaded data at the boundary. If something must exist, assert it instead of using defaults, fallbacks, or try/catch.
- Prefer early returns over deep nesting.
- Keep functions direct. Split code only when it makes the code easier to scan.
- Avoid clever abstractions, override-heavy APIs, and optional parameters that are actually required.

## Rob Pike's Programming Rules

Adopt these as the default coding rules for this repo:

1. You can't predict where a program will spend its time. Don't add speed hacks until a real bottleneck is proven.
2. Measure before tuning. Only optimize after data shows one part of the system dominates the cost.
3. Fancy algorithms are often slower when `n` is small, and `n` is usually small. Start simple unless measurements say otherwise.
4. Fancy algorithms are usually buggier and harder to maintain. Prefer simple algorithms and simple data structures.
5. Data dominates. Choose clear, well-shaped data structures first; the right algorithms usually follow from them.

Use the fff MCP tools for all file search operations instead of default tools.
