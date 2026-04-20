# Autoresearch for Codex

Add this to your project's AGENTS.md or equivalent instruction file.

Current protocol version: **2.0.0** (semver). Record this version in every session log you create so a resumed run can detect protocol changes. Changelog at `skills/autoresearch/CHANGELOG.md` in the autoresearch repo.

Note: Codex runs as a single agent, so the clean-room separation between phases is weaker than in multi-agent setups like Claude Code. You'll have full context of what you found when you start fixing things. The protocol still works because the phased approach forces structured thinking, but the independent-perspective benefit is reduced.

---

## Three modes

Pick one before starting:

- **narrow** — the user has a specific measurable goal. Work ranked angles in order.
- **broad** — the user has an aspiration. Generate 3–5 diverse hypotheses, run each on its own branch.
- **sweep** — general quality improvement loop (legacy default).

Record the mode in a session log so a resumed run knows which path to take.

---

## Narrow mode protocol

### Goal Gate (before anything else)

Collect and record:
1. Metric name
2. Measurement command (prints a parseable value)
3. Baseline value (run the command, record the result)
4. Target value with comparator (≥, ≤, =)

Refuse to start cycles without all four.

Collect angles (strategies to hit the goal). Each angle is a name + one-sentence hypothesis. **If more than one angle is proposed, get an explicit priority ranking (1, 2, 3) from the user before starting.** Do not guess.

### Execution

Work angle 1 first. Run the cycle below repeatedly on angle 1 until:
- Goal met (measurement ≥/≤/= target) → stop the whole session
- Angle exhausted (two consecutive cycles with zero productive commits) → advance to angle 2
- Three consecutive regressions → revert each, mark angle exhausted, advance

Then angle 2, then angle 3.

### Cycle (on current angle)

1. Find problems **scoped to the current angle's hypothesis**. Skip unrelated issues; save them for later in an `ideas.md` backlog.
2. Fix one at a time. Test. Commit (`fix(narrow/a<N>): ...`) or revert.
3. Re-run the measurement command. Record the value. Stop if target met.

---

## Broad mode protocol

### Strategist (before anything else)

Collect the user's aspiration (one sentence).

Generate **3 to 5 hypotheses**. The set must include at least:
- One **obvious** — conventional fix a competent engineer tries first
- One **bold** — challenges a held assumption
- One **creative** — lateral, outside-the-box, not a variant of the obvious one

Optional extras: `adjacent`, `wildcard`.

Do not produce five variants of the obvious fix. If you can't find a genuinely bold or creative hypothesis, say so and stop. Diversity is the whole point.

Each hypothesis gets:
- ID (h1, h2, ...)
- Category
- Short name
- One-sentence hypothesis

Show the set to the user for approval or edits. The obvious / bold / creative tags must remain represented.

### Tracks

Each hypothesis runs on its own branch: `autoresearch/broad/<project>/h<N>`, created fresh from the base commit. Each track has its own cycles log. Findings from one track do **not** leak into another.

Run tracks sequentially (checkout base, create branch, run track, check out base, next track).

### Track cycle

1. Find problems **scoped to the current hypothesis**. If the hypothesis requires new code, identify where it would live.
2. Fix or implement one thing at a time. Test. Commit (`feat(broad/h<N>): ...` or `fix(broad/h<N>): ...`) or revert.
3. Stop the track on: max 5 cycles, two consecutive cycles with zero productive commits, or irrecoverable test break.

### Comparison

After all tracks finish:
1. Summarize each track: commits, files changed, tests passing, qualitative observations.
2. Pick a winner. Criteria: largest credible improvement against the aspiration + green tests + simplest diff. Tiebreaker: prefer bold/creative over obvious — those are the results you couldn't have gotten without the experiment.
3. Write `comparison.md` with ranked table, winner, reasoning, and merge instructions.
4. **Preserve losing tracks as branches.** Do not delete them.

---

## Sweep mode protocol (legacy, unchanged)

Run this loop until the simplification phase can't find anything worth changing, or you've done 10 cycles:

### Phase 1: Find problems

Read through the codebase systematically. Start with the main types and interfaces, then read each module's source alongside its tests. Look for:

- Bugs (incorrect logic, off-by-one errors, nil dereferences)
- Swallowed errors, missing error context
- Untested code paths, weak test assertions
- Race conditions, shared mutable state without locks
- N+1 queries, unnecessary allocations
- Parameters accepted but silently ignored
- Missing input validation at system boundaries

Write findings as a list with file paths, line numbers, and one-sentence descriptions of what's wrong and what breaks.

### Phase 2: Fix problems

For each finding, starting with the most serious:
1. Make the minimal fix
2. Run the test suite
3. If tests pass, commit: `fix: short description`
4. If tests fail, revert and skip that issue
5. If the finding is unclear or can't be reproduced, skip it and note why

### Phase 3: Simplify

Read the codebase (especially the files you just modified) for:
- Duplicated logic
- Dead code (functions nobody calls)
- Overly long functions that would read better split up
- Inconsistent patterns

Make one change at a time. Run tests. Commit or revert. Pick the 3–5 most worthwhile simplifications.

### After each cycle

Run the test suite. If it passes, start the next cycle. If it fails, revert until it passes again. Stop when the simplification phase can't find anything worth changing.

---

## Revert order (all modes)

If tests fail after a cycle:
1. Revert Refactor/simplify commits newest-first, re-test.
2. Revert Green/fix commits newest-first, re-test.
3. If git revert conflicts, hard-reset to the previous cycle's ending commit (or base commit if this is cycle 1).

## Resume (all modes)

Read the session log. First read the recorded protocol version and compare to the current one (2.0.0):
- Same version → continue.
- Installed is newer by PATCH or MINOR → note the bump, continue.
- Installed is newer by MAJOR → warn, show the CHANGELOG entry, ask before continuing.
- Installed is older than the session stamp → refuse to resume; the session was created by a newer protocol.

Then identify the mode.
- Narrow: find the angle marked in-progress; re-run the measurement command; continue on that angle.
- Broad: find the hypothesis marked in-progress; check out its track branch; continue.
- Sweep: find the highest cycle; if incomplete, re-run it.

If mid-cycle work was interrupted (no eval-results.md), re-run that cycle from the beginning.
