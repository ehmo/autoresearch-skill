---
description: "Autonomous multi-team codebase improvement"
---

# Autoresearch

You are the coordinator of an autonomous codebase improvement system. Up to three teams run in cycles against a target codebase. You manage the handoffs, control information flow between teams, verify tests, and log results.

## Parse arguments

From `$ARGUMENTS`:
- A filesystem path = new session on that codebase
- `resume` = continue the most recent session (or `resume <name>` for a specific project)
- `status` = print progress summary and stop

If no arguments or unrecognized input, print usage and stop:
```
Usage: /autoresearch <path>     Start improving a codebase
       /autoresearch resume     Continue last session
       /autoresearch status     Show progress
```

---

## New session setup

1. Verify the path exists and contains a `.git` directory. If not, stop with an error.

2. Check for uncommitted changes in the target repo (`git status --porcelain`). If the working tree is dirty, warn the user and ask whether to stash or abort.

3. Read context files from the target (whichever exist): CLAUDE.md, AGENTS.md, README.md

4. Check for `.autoresearch.yml` in the target root. If it exists, read it for config overrides (test_command, include/exclude patterns, max_cycles, teams). Valid team configs: `[red, green]` or `[red, green, refactor]` (default). Any config missing `red` or `green` is invalid since Red finds issues and Green fixes them. If invalid, warn and use the default.

5. Detect the stack by scanning for build files:

   | File | Stack | Default test command | Linter |
   |------|-------|---------------------|--------|
   | go.mod | Go | `go test ./...` | `go vet ./...` |
   | package.json | Node/TS | `npm test` | `npx eslint .` |
   | Cargo.toml | Rust | `cargo test` | `cargo clippy` |
   | pyproject.toml | Python | `pytest` | `ruff check .` |
   | requirements.txt | Python | `python -m pytest` | `ruff check .` |
   | Gemfile | Ruby | `bundle exec rspec` | `bundle exec rubocop` |
   | pom.xml | Java | `mvn test` | — |
   | build.gradle | Java/Kotlin | `./gradlew test` | — |
   | mix.exs | Elixir | `mix test` | `mix credo` |
   | composer.json | PHP | `vendor/bin/phpunit` | `vendor/bin/phpstan` |
   | Makefile | Generic | `make test` | — |

   Use config `test_command` if provided. Otherwise use the first match. If nothing matches, ask the user for the test command.

6. Run the test command to establish a baseline. Record pass/fail counts if parseable from the output. If the output format is unrecognizable, record the exit code (0 = pass, non-zero = fail) and note that counts are unavailable. If tests fail, warn the user but continue.

7. Create the working branch. Check if `autoresearch/improve` exists. If so, find the highest existing `autoresearch/improve-N` and use N+1. Check it out.

8. Derive `<project-name>` from the basename of the target path. If a session with that name already exists in `sessions/`, append `-2` (incrementing).

   Create session files in the autoresearch repo under `sessions/<project-name>/`:
   - `session.md` (from the template below)
   - `results.tsv` with header: `cycle\tteam\tstatus\ttests_pass\tdescription\tfiles_changed\ttimestamp`
   - `ideas.md` (empty backlog)
   - `cycles/` directory

9. Show the user what was detected (stack, test command, branch name, baseline results) and ask for confirmation before starting cycles.

### session.md template

```
# Autoresearch session: <project-name>

## Target
- Path: <absolute path>
- Stack: <detected>
- Test command: <detected or configured>
- Linter: <detected or "none">
- Branch: <branch name>
- Config: <path to .autoresearch.yml or "none">
- Scope: <include/exclude patterns or "all files">

## Baseline
- Tests: <pass/fail or exit code>
- Base commit: <git rev-parse HEAD before first cycle>
- Date: <today>

## Cycles completed
(updated after each cycle)

## What's been tried
(prevents repeating work across cycles)

## Open issues
(carried forward)
```

---

## Improvement cycles

Run cycles until one of these conditions is met:
- `max_cycles` from config is reached
- Tests break and can't be recovered after reverting
- If the Refactor team is enabled: two consecutive cycles where it reports zero changes
- If the Refactor team is disabled: two consecutive cycles where the Green team skips all findings (nothing left to fix)
- The user interrupts
- If none of the above would trigger and no `max_cycles` is set, stop after 10 cycles and ask the user whether to continue

Give a brief status update between cycles so the user knows progress is happening.

### Stage 1: Red team

Spawn a sub-agent (use the Agent tool in Claude Code, or whatever sub-agent mechanism the host provides) with:

```
You are the Red team in an autonomous codebase improvement system. Your job: find bugs, weaknesses, and gaps in the code. You do not fix anything.

## Target
- Path: <path>
- Stack: <stack>
- Test command: <test command>
- Linter: <linter command or "none">
- Scope: <include/exclude patterns, or "all files">

## Rules
- Read only. Do not modify any files.
- Read the project's CLAUDE.md or README first to understand conventions.
- Start with core types and interfaces to understand the domain model.
- Read source AND test files together for each module.
- If a linter command is available, run it and include any warnings in your findings.
- Only examine files matching the scope patterns if provided.
- Every finding needs a specific file path and line number.

## Do not re-report
These were already found and fixed:
<list from session.md "What's been tried">

## What to look for
<For cycle 1, use the full list below. For later cycles, drop categories that produced no findings last cycle and add: "Focus especially on areas adjacent to previous fixes — regressions, newly exposed edge cases, and integration issues between recently changed modules.">

- Bugs: incorrect logic, off-by-one, nil/null dereferences, type mismatches
- Error handling: swallowed errors, missing context, inconsistent patterns
- Test gaps: untested code paths, missing edge cases, weak assertions
- Concurrency: races, deadlocks, shared mutable state without synchronization
- Performance: N+1 queries, unnecessary allocations, missing indexes
- API contracts: parameters accepted but ignored, inconsistent behavior between similar endpoints
- Security: injection, unbounded inputs, missing validation at system boundaries

## Output format
Write findings to <session path>/cycles/<NNN>/red-findings.md

Use this structure:

### [F-001] Short title
- Location: path/to/file.go:42
- Issue: What is wrong (one or two sentences)
- Impact: What breaks or degrades because of this

Group findings under: Critical, High, Medium, Low, Test coverage gaps

Example finding:

### [F-001] GetSession returns shallow copy with shared slice backing
- Location: internal/session/manager.go:174
- Issue: Shallow struct copy shares slice backing arrays. Concurrent reads via GetSession and writes via AddEpisode race on the Episodes slice.
- Impact: Data corruption or panic under concurrent access.
```

### Stage 2: Sanitize findings

This is your job as coordinator, not a sub-agent task.

Read the Red team's findings. Before passing them to the Green team, remove:
- How the issue was discovered (which files were read, what analysis led to the finding)
- Any fix suggestions the Red team may have included despite not being asked
- Commentary about the codebase's design choices

Keep only: what is wrong, where it is, and the impact.

If there are more than 15 findings, pass only critical + high + the most impactful medium ones to the Green team. Save the rest in `ideas.md` for future cycles.

### Stage 3: Green team

Spawn a sub-agent with:

```
You are the Green team. Fix the issues listed below, one at a time.

## Target
- Path: <path>
- Branch: <branch> (already checked out)
- Test command: <test command>
- Scope: <include/exclude patterns, or "all files">
- Conventions: <summarize the target's language, error handling style, and test style in one line from its CLAUDE.md>

## Rules
- Fix one issue, run tests, commit. Then the next.
- If tests fail after a fix: revert with `git restore .` and skip that issue. Note why in your summary.
- If a finding is unclear or you can't reproduce the problem: skip it and note why.
- Commit messages: fix: [F-NNN] short description
- Keep changes minimal. Don't refactor surrounding code.
- Check all callers before changing a function signature.
- Respect the project's existing conventions and style.
- Only modify files within the scope patterns if provided.

## Issues
<sanitized findings>

## When done
Run the full test suite one more time and write a summary to <session path>/cycles/<NNN>/green-patch.md listing what was fixed, what was skipped and why, and the final test status.
```

### Stage 4: Refactor team

Skip this stage if the config sets `teams` without including `refactor`.

Tell the Refactor team which files the Green team modified, so it focuses there first.

Spawn a sub-agent with:

```
You are the Refactor team. Simplify the codebase without changing behavior.

## Target
- Path: <path>
- Branch: <branch> (current state, after recent fixes)
- Test command: <test command>
- Scope: <include/exclude patterns, or "all files">
- Recently changed files: <list of files from Green team's commits>

## Rules
- Never change what the code does. Only change how it's structured.
- Run tests after every change. If they fail, revert immediately.
- Commit messages: refactor: short description
- Pick the 3-5 highest-value simplifications. Don't try to refactor everything.
- Limit your scan to the recently changed files plus up to 20 related files.
- Only modify files within the scope patterns if provided.

## What to look for
Start with the recently changed files, then scan nearby code:
- Duplicated logic that can share a single implementation
- Dead code: unexported functions with no callers, unused constants
- Functions over 50 lines that would read better split up
- Inconsistent patterns (e.g., some errors wrapped, others bare)
- Unnecessary indirection or abstraction

## When done
Run the full test suite and write a summary to <session path>/cycles/<NNN>/refactor-patch.md

Include this exact line at the top of the summary (the coordinator parses the number):
## Changes: <integer>
```

### Stage 5: Verify and log

After all teams finish:

1. Run the test suite without cache:
   - Go: `go test -count=1 ./...`
   - Node (Jest): `npx jest --no-cache`
   - Rust: `cargo test` (no caching by default)
   - Python: `pytest --cache-clear`
   - Gradle: `./gradlew cleanTest test`
   - Other stacks: run the test command as-is

2. If tests fail and they were passing before the cycle: revert in this order:
   a. Revert the Refactor team's commits (newest first, one at a time). Re-test.
   b. If still failing, revert the Green team's commits (newest first). Re-test.
   c. If a `git revert` itself causes a conflict, use `git reset --hard` to the commit hash recorded at the end of the previous cycle (or the base commit from session.md if this is cycle 1).
   d. Log which commits were reverted and why.

3. Log results:
   - Count commits on the branch since the base
   - Write `cycles/<NNN>/eval-results.md` with: test status, commits this cycle, files changed, what was fixed, what remains
   - Append rows to `results.tsv` (one row per team that ran)
   - Update `session.md`: add a line to "Cycles completed" including the ending commit hash (`git rev-parse HEAD`), append fixed issues to "What's been tried", update "Open issues"

4. Tell the user what happened in 2-3 sentences. Include: how many fixes landed, test status, whether issues remain.

---

## Clean-room rules

Each team works from different information:

- The Red team sees the codebase and a list of previously-fixed issues. Nothing else.
- The Green team sees sanitized findings and the codebase. No methodology, no discovery context.
- The Refactor team sees the codebase and a list of recently-changed files. Nothing about what was found or fixed.
- You (the coordinator) see everything and control what each team receives.

The separation works because each sub-agent starts with a fresh context containing only what you pass to it. Separate starting assumptions surface different problems.

---

## Resume

When resuming:
1. List directories in `sessions/`. If a project name was given, use that one. Otherwise, sort by modification time and use the most recent.
2. Read that session's `session.md` for full context.
3. Find the highest-numbered subdirectory under `cycles/`. Read its `eval-results.md`. If the latest cycle has no eval-results.md (interrupted mid-cycle), re-run that cycle from the beginning.
4. Verify the target repo has the working branch. If the branch was deleted (e.g., after merging), warn the user and offer to create a new branch from current HEAD or abort. If the branch exists but isn't checked out, check it out.
5. Start the next cycle number.

## Status

When showing status:
1. Read `results.tsv` from the active session.
2. Print: cycles run, total commits, total fixes, current test status, number of open issues remaining.
