---
name: autoresearch
description: "Autonomous multi-team codebase improvement with narrow (goal-directed) and broad (hypothesis-divergent) modes"
version: 2.0.0
---

# Autoresearch

Current version: **2.0.0** (semver). Changelog: `skills/autoresearch/CHANGELOG.md`.

Version scheme:
- MAJOR — protocol-breaking changes (new modes, incompatible session layout, changed team contract).
- MINOR — new features that existing sessions can ignore without breaking.
- PATCH — wording fixes, bug fixes, clarifications.

When you start a new session, stamp the skill version into `session.md` (field: `Skill version`). When resuming, read that stamp and compare to the current version — if they differ, note the delta to the user and continue with the newer version unless the change was MAJOR (in which case warn and ask).

You coordinate an autonomous codebase improvement system. Up to three teams run in cycles against a target codebase. You manage handoffs, control information flow, verify tests, and log results.

Autoresearch has three execution modes:

- **narrow** — the user has a specific measurable goal. You work priority-ranked angles in order until the goal is met or exhausted.
- **broad** — the user has an aspiration. You generate 3–5 categorically-diverse hypotheses (obvious + bold + creative at minimum) and run each on its own independent track, then compare.
- **sweep** (default when no mode is specified) — general quality improvement with no specific target. Cycles of Red → Green → Refactor until diminishing returns.

Clean-room information barriers between Red, Green, and Refactor teams apply in all three modes.

---

## Parse arguments

From `$ARGUMENTS`:

- `narrow <path>` → narrow mode, new session on that codebase
- `broad <path>` → broad mode, new session on that codebase
- A bare filesystem path = sweep mode, new session
- `resume` = continue the most recent session (mode is read from `session.md`)
- `resume <name>` = continue a named session
- `status` = print progress summary and stop
- `version` = print the current skill version (from frontmatter) and stop

If no arguments or unrecognized input, print usage and stop:

```
Usage: /autoresearch narrow <path>  Drive a specific measurable goal
       /autoresearch broad <path>   Explore 3–5 diverse hypotheses
       /autoresearch <path>         General quality sweep (legacy)
       /autoresearch resume         Continue last session
       /autoresearch status         Show progress
       /autoresearch version        Print skill version
```

Record the chosen mode in `session.md` so `resume` can dispatch correctly.

---

## Shared new-session setup

Run these steps regardless of mode:

1. Verify the path exists and contains a `.git` directory. If not, stop with an error.

2. Check for uncommitted changes in the target repo (`git status --porcelain`). If the working tree is dirty, warn the user and ask whether to stash or abort.

3. Read context files from the target (whichever exist): CLAUDE.md, AGENTS.md, README.md.

4. Check for `.autoresearch.yml` in the target root. If it exists, read it for config overrides (test_command, include/exclude patterns, max_cycles, teams, mode). Valid team configs: `[red, green]` or `[red, green, refactor]` (default). Any config missing `red` or `green` is invalid since Red finds issues and Green fixes them. If invalid, warn and use the default.

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

7. Derive `<project-name>` from the basename of the target path. If a session with that name already exists in `sessions/`, append `-2` (incrementing). Create the session directory under `sessions/<project-name>/`.

8. Create the working branch. The naming depends on mode:
   - **sweep**: `autoresearch/improve` (fall back to `autoresearch/improve-N` if taken)
   - **narrow**: `autoresearch/narrow/<project-name>`
   - **broad**: base branch `autoresearch/broad/<project-name>`; one track branch per hypothesis (see Broad mode)

9. Initialize session files. Every mode writes:
   - `session.md` (from the template below, filled in)
   - `results.tsv` with header: `cycle\tteam\tstatus\ttests_pass\tdescription\tfiles_changed\ttimestamp`
   - `ideas.md` (empty backlog)
   - `cycles/` directory (narrow: cycles live here; broad: per-track subdirectories live here — see Broad mode)

10. Branch to the mode-specific setup stage:
    - **sweep** → jump to "Improvement cycles" below
    - **narrow** → run "Narrow: Goal Gate" next
    - **broad** → run "Broad: Strategist" next

### session.md template

```
# Autoresearch session: <project-name>

## Skill version
<major.minor.patch at the time this session was created>

## Mode
<narrow | broad | sweep>

## Target
- Path: <absolute path>
- Stack: <detected>
- Test command: <detected or configured>
- Linter: <detected or "none">
- Branch: <branch name or "see tracks">
- Config: <path to .autoresearch.yml or "none">
- Scope: <include/exclude patterns or "all files">

## Baseline
- Tests: <pass/fail or exit code>
- Base commit: <git rev-parse HEAD before first cycle>
- Date: <today>

## Goal (narrow only)
- Metric: <name>
- Measurement command: <cmd that prints the value>
- Baseline value: <number + units>
- Target value: <number + units, with comparator ≥ ≤ = >
- Current value: <updated after each cycle>

## Angles (narrow only)
| Priority | Name | Hypothesis | Status |
|----------|------|-----------|--------|
| 1        | ...  | ...       | not-started | in-progress | exhausted | goal-met |
| 2        | ...  | ...       | ...                                                  |
| 3        | ...  | ...       | ...                                                  |

## Hypotheses (broad only)
| ID | Category | Name | Hypothesis | Branch | Status |
|----|----------|------|------------|--------|--------|
| h1 | obvious  | ...  | ...        | ...    | not-started | in-progress | complete | aborted |
| h2 | bold     | ...  | ...        | ...    | ...                                                |
| h3 | creative | ...  | ...        | ...    | ...                                                |
| h4 | adjacent | ...  | ...        | ...    | ...                                                |
| h5 | wildcard | ...  | ...        | ...    | ...                                                |

## Cycles completed
(updated after each cycle; in broad mode, scoped to the current track)

## What's been tried
(prevents repeating work across cycles)

## Open issues
(carried forward)
```

---

## Narrow mode

Narrow mode is for when the user wants something specific and measurable to change. You do not run general quality sweeps; you drive the metric toward the target.

**Safeguards.** The Clean-room rules and the revert order defined in "Verify and log" apply to narrow mode without exception. The Red team sees only the current angle; the Green team sees only sanitized findings; the Refactor team, if enabled, sees only a list of recently-changed files. If a cycle breaks tests, revert in the order refactor → green → hard-reset. Do not bypass these in narrow mode, even when a fix would obviously move the metric.

### Narrow: Goal Gate (runs before any cycle)

Before the first cycle can start, you **must** collect and record a goal specification. Ask the user for:

1. **Metric name** — a short label for what is being measured. Examples: `p99 latency`, `test coverage`, `bundle size`, `lint warnings`, `benchmark score`.
2. **Measurement command** — a shell command that, when run inside the target repo, prints a single parseable value. Examples: `make bench-p99`, `go test -cover ./... | awk '/coverage/ {print $5}'`, `wc -c < dist/bundle.js`.
3. **Baseline value** — run the measurement command immediately and record the value. This is the before-number.
4. **Target value** — a number with a comparator (`≥`, `≤`, `=`). Examples: `≤100ms`, `≥80%`, `<200000` (bytes), `=0` (warnings).

If any of these four pieces is missing, **do not start cycles**. Ask again. Narrow mode without a measurable target is not allowed — degrade to sweep mode or abort if the user refuses.

Then collect **angles** — strategies for moving the metric. The user proposes one or more. Each angle has:
- A short name
- A one-sentence hypothesis

### Narrow: priority ranking (mandatory if >1 angle)

If the user proposes more than one angle, you **must** get an explicit priority ranking (`1`, `2`, `3`, …) before any cycle runs. Do not guess the ranking. Do not start cycles with an unranked list — refuse and prompt the user again. Angle 1 is attempted before angle 2; angle 2 before angle 3. There are no parallel angles in narrow mode.

Record the ranked angle table in `session.md`. Mark angle 1 as `in-progress` and the rest as `not-started`.

### Narrow: execution

Work angle 1 first. Keep cycling Red → Green → Refactor on angle 1 until one of the following happens:

1. **Goal met** — the measurement command shows the metric has reached or passed the target. Stop the whole session. Write `goal-progress.md` with the final value and commit history.
2. **Angle exhausted** — two consecutive cycles where Green team commits nothing attributable to this angle's hypothesis. Mark angle 1 as `exhausted` and advance to angle 2.
3. **Regression** — the metric is worse than baseline after a cycle. Revert the offending cycle (see "Verify and log"), then continue on the same angle. Three consecutive regressions on the same angle → mark as `exhausted` and advance.

When angle 1 is exhausted, promote angle 2 to `in-progress`. When angle 2 is exhausted, advance to angle 3. Stop the session when all angles are exhausted or the goal is met.

### Narrow: Red team prompt override

In narrow mode, replace the Red team's "What to look for" list with this, tuned to the current angle:

```
You are scoped to one angle only: <angle name>
Hypothesis: <angle hypothesis>
Metric: <metric name>
Current value: <current>
Target: <target>

Find code locations where working on this angle would plausibly move the metric.
Ignore findings unrelated to the current angle — they belong in ideas.md for a future session.
Every finding needs a specific file path, line number, and a one-sentence explanation of how fixing it helps the metric.
```

The Green team still gets only sanitized findings (what and where). The Refactor team runs in narrow mode on the same terms as sweep mode — it is included by default and only skipped when `.autoresearch.yml` explicitly omits it from `teams`. The clean-room information barriers between Red, Green, and Refactor apply in narrow mode without exception.

### Narrow: per-cycle measurement

After every cycle, in the "Verify and log" stage:

1. Run the measurement command.
2. Update `session.md` "Current value".
3. Append to `goal-progress.md`: `cycle N | <value> | Δ from baseline | Δ from previous`.
4. Compare to target:
   - If target met → stop session, write final report.
   - If regressed vs. baseline → revert the cycle, increment regression counter for the current angle.
   - Otherwise → continue to next cycle on the same angle.

---

## Broad mode

Broad mode is for when the user has an aspiration without a narrow metric. You generate diverse hypotheses and test each on its own track.

**Safeguards.** The Clean-room rules and the revert order defined in "Verify and log" apply to broad mode without exception. They apply **per track** — Red/Green/Refactor barriers hold within each hypothesis's cycles, and the clean-room rule also applies **between tracks** (a later track does not see earlier tracks' findings or diffs). If a cycle breaks tests, revert in the order refactor → green → hard-reset, scoped to the current track's branch.

### Broad: Strategist (runs before any cycle)

Collect from the user a one-sentence **aspiration** — what they want more of, or what they want changed qualitatively. Example: "Make this CLI dramatically faster to use every day."

Then generate **exactly 3 to 5 hypotheses**. Fewer than 3 → ask for more. More than 5 → prune to the top 5. Each hypothesis must have:

- An ID (`h1`, `h2`, ...)
- A category tag (see below)
- A short name
- A one-sentence hypothesis statement

**Required categories.** Your set of hypotheses must include at least one of each of these three:

- **obvious** — the conventional fix a competent engineer would try first.
- **bold** — challenges a held assumption about the codebase or the problem. Something that would make a maintainer say "I'd never do that" before thinking about it.
- **creative** — lateral, outside-the-box. Not a variant of the obvious hypothesis. Approaches the aspiration from an angle the user almost certainly hasn't considered.

Optional categories if you want 4 or 5 hypotheses:

- **adjacent** — one step off the obvious path.
- **wildcard** — an experiment that might fail entirely but would be interesting.

Do not generate five hypotheses that are all variants of each other. Diversity is the point. If you cannot find a genuinely bold or creative hypothesis, say so and stop — broad mode depends on divergent tracks.

Write the hypothesis table to `session.md` and show it to the user. Ask for approval or edits. The user may rewrite any hypothesis, but the `obvious`, `bold`, and `creative` tags must all remain represented in the final set.

### Broad: independent tracks

Each hypothesis runs on its own **track**. A track is:

- **Branch**: `autoresearch/broad/<project-name>/<hypothesis-id>`, created fresh from the base commit (not from another track)
- **Cycles directory**: `sessions/<project-name>/cycles/<hypothesis-id>/001/`, `002/`, ...
- **Results log**: appended to `results.tsv` with a `track` column populated

Tracks do not share findings. Each track's Red team starts clean, knowing only the hypothesis it is testing. A finding from h1 does not influence h2. This is the whole point — we want genuinely different paths to be explored, and leaks between tracks collapse diversity.

Run tracks sequentially by default: finish h1, checkout base commit, create h2 branch, finish h2, and so on. If the config sets `parallel: true`, and the host supports it, tracks may run concurrently — but their branches must remain independent.

### Broad: Red team prompt override

In broad mode, replace the Red team's "What to look for" list with this, tuned to the current track:

```
You are scoped to one hypothesis only: <hypothesis name> (<category>)
Hypothesis: <hypothesis statement>
Aspiration: <user aspiration>

Find code locations where this hypothesis would plausibly be tested or implemented.
If the hypothesis requires new code rather than changes to existing code, identify the files where that new code would live and the interfaces it would touch.
Every finding needs a specific file path and a one-sentence explanation of how it connects to the hypothesis.
```

Green team and Refactor team rules are unchanged — they receive sanitized findings and commits that stay on the track's branch.

### Broad: per-track termination

A single track stops when any of these hit:

- `max_cycles` (per-track, default 5)
- Two consecutive cycles with zero Green commits
- Tests break irrecoverably
- The user interrupts and advances to the next track

When one track terminates, record its status in the hypothesis table (`complete` or `aborted`), check out the base commit, create the next track's branch, and continue.

### Broad: comparison and winner

After all tracks finish (or all have been attempted), run the comparison stage. This is **not** a sub-agent task — it is your job as coordinator:

1. For each track, summarize: commits, files changed, tests passing, qualitative observations.
2. Pick a winner. Criteria: largest credible improvement against the aspiration, test suite still green, simplest diff. If multiple tracks tie, prefer the less-obvious category (bold or creative over obvious) because those are the results you couldn't have gotten without the experiment.
3. Write `sessions/<project-name>/comparison.md` with:
   - The ranked table of tracks
   - Explicit winner declaration with reasoning
   - Merge instructions (`git merge <winner-branch>` against main or a review branch)
4. **Preserve losing tracks as branches.** Do not delete them. They are the experiment record and may contain useful intermediate work the user wants to revisit.

Tell the user what happened: winner, runner-up, and any track that produced unexpected insight even if it lost.

---

## Sweep mode (default)

Sweep mode is the general quality improvement loop. Use it when the user has no specific metric or aspiration — they just want the code better.

Run cycles until one of these is met:

- `max_cycles` from config is reached
- Tests break and can't be recovered after reverting
- If the Refactor team is enabled: two consecutive cycles where it reports zero changes
- If the Refactor team is disabled: two consecutive cycles where the Green team skips all findings
- The user interrupts
- If none of the above would trigger and no `max_cycles` is set, stop after 10 cycles and ask the user whether to continue

Give a brief status update between cycles so the user knows progress is happening.

Red team prompt in sweep mode uses the general "What to look for" list (see below).

---

## Improvement cycles (shared by all modes)

Each cycle runs the same four stages. Modes differ in what the Red team is looking for and when the outer loop stops, not in the cycle shape itself.

### Stage 1: Red team

Spawn a sub-agent with:

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
<mode-specific block — see per-mode overrides above. For sweep mode and cycle 1 of narrow/broad mode when no better list applies, use:>

- Bugs: incorrect logic, off-by-one, nil/null dereferences, type mismatches
- Error handling: swallowed errors, missing context, inconsistent patterns
- Test gaps: untested code paths, missing edge cases, weak assertions
- Concurrency: races, deadlocks, shared mutable state without synchronization
- Performance: N+1 queries, unnecessary allocations, missing indexes
- API contracts: parameters accepted but ignored, inconsistent behavior between similar endpoints
- Security: injection, unbounded inputs, missing validation at system boundaries

<For later cycles in sweep mode, drop categories that produced no findings last cycle and add: "Focus especially on areas adjacent to previous fixes — regressions, newly exposed edge cases, and integration issues between recently changed modules.">

## Output format
Write findings to <session path>/cycles/<track-or-cycle-path>/red-findings.md

Use this structure:

### [F-001] Short title
- Location: path/to/file.go:42
- Issue: What is wrong (one or two sentences)
- Impact: What breaks or degrades because of this

Group findings under: Critical, High, Medium, Low, Test coverage gaps.
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
Run the full test suite one more time and write a summary to <session path>/cycles/<track-or-cycle-path>/green-patch.md listing what was fixed, what was skipped and why, and the final test status.
```

### Stage 4: Refactor team

Skip this stage **only** if `.autoresearch.yml` sets `teams` without including `refactor`. The skip is purely config-driven. Do not skip Refactor based on coordinator judgment in any mode — doing so would bypass the Red → Green → Refactor clean-room pipeline.

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
Run the full test suite and write a summary to <session path>/cycles/<track-or-cycle-path>/refactor-patch.md

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

2. If tests fail and they were passing before the cycle: revert in this order (applies in all modes):
   a. Revert the Refactor team's commits (newest first, one at a time). Re-test.
   b. If still failing, revert the Green team's commits (newest first). Re-test.
   c. If a `git revert` itself causes a conflict, use `git reset --hard` to the commit hash recorded at the end of the previous cycle (or the base commit from session.md if this is cycle 1).
   d. Log which commits were reverted and why.

3. **Narrow mode only**: re-run the measurement command. Update `session.md` "Current value" and append to `goal-progress.md`. Evaluate:
   - Target met → stop the whole session, write final report.
   - Regression vs. baseline → revert the cycle, increment regression counter for the current angle.
   - Otherwise → continue.

4. Log results:
   - Count commits on the branch (or track branch) since the base
   - Write `cycles/<track-or-cycle-path>/eval-results.md` with: test status, commits this cycle, files changed, what was fixed, what remains (narrow: + current metric value; broad: + hypothesis observations)
   - Append rows to `results.tsv` (one row per team that ran; broad mode populates the `track` column)
   - Update `session.md`: add a line to "Cycles completed" including the ending commit hash (`git rev-parse HEAD`), append fixed issues to "What's been tried", update "Open issues"

5. Tell the user what happened in 2-3 sentences. Include: how many fixes landed, test status, and the mode-specific update (narrow: metric delta; broad: current track status; sweep: nothing extra).

---

## Clean-room rules (applies in all three modes)

Each team works from different information:

- The Red team sees the codebase, a list of previously-fixed issues, and (in narrow/broad modes) the current angle or hypothesis. Nothing else.
- The Green team sees sanitized findings and the codebase. No methodology, no discovery context, no knowledge of the overarching angle or hypothesis beyond what's implicit in the sanitized findings.
- The Refactor team sees the codebase and a list of recently-changed files. Nothing about what was found or fixed.
- You (the coordinator) see everything and control what each team receives.

In broad mode, clean-room also applies **between tracks**: the Red team for h2 does not see h1's findings or diffs. Each track starts from the base commit with fresh context.

The separation works because each sub-agent starts with a fresh context containing only what you pass to it. Separate starting assumptions surface different problems.

---

## Resume

When resuming:

1. List directories in `sessions/`. If a project name was given, use that one. Otherwise, sort by modification time and use the most recent.
2. Read that session's `session.md`. **Read the `Skill version` field first** and compare to the current skill version in this file's frontmatter:
   - Same version → continue.
   - Current version is newer by PATCH or MINOR → tell the user which version bump happened (one line, e.g. "skill upgraded 2.0.0 → 2.1.0"), then continue. Backwards-compatible by contract.
   - Current version is newer by MAJOR → warn the user, show the CHANGELOG entry for the major bump, and ask whether to continue with the newer protocol or stop.
   - Current version is older than the session stamp → warn that the installed skill is older than the session; refuse to resume until the user upgrades, since downgrading the protocol may corrupt session state.
3. **Then read the `Mode` field** and dispatch to the right resume path:
   - `sweep` → find the highest-numbered subdirectory under `cycles/`, read its `eval-results.md`. If missing (interrupted mid-cycle), re-run that cycle from the beginning. Then continue.
   - `narrow` → read the Angles table. Find the angle marked `in-progress`. Look under `cycles/` for the highest-numbered subdirectory whose commits belong to this angle. If its `eval-results.md` is missing, re-run that cycle. Re-run the measurement command to get the current value before the next cycle. Continue on the same angle.
   - `broad` → read the Hypotheses table. Find the first hypothesis whose status is `in-progress` (or the first `not-started` if no track is mid-run). Check out that track's branch (`autoresearch/broad/<project-name>/<id>`). Look under `cycles/<id>/` for the highest-numbered subdirectory. If its `eval-results.md` is missing, re-run that cycle. Continue on the same track.
4. Verify the target repo has the working branch (or track branch). If it was deleted (e.g., after merging), warn the user and offer to create a new branch from current HEAD or abort. If it exists but isn't checked out, check it out.
5. Start the next cycle.

## Status

When showing status:
1. Read `results.tsv` and `session.md` from the active session.
2. Print skill version (from the session stamp; note if it differs from the currently installed version), mode, cycles run, total commits, total fixes, current test status, number of open issues.
3. Mode-specific extras:
   - `narrow` → print the metric: baseline, current, target, delta; plus angle progress table.
   - `broad` → print the hypothesis table with status per track.
   - `sweep` → no extras.

## Version

When `$ARGUMENTS` is `version`:
1. Read this file's YAML frontmatter `version:` field.
2. Print it in the form `autoresearch skill <version>` and stop. Do not open a session.
