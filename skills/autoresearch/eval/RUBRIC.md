# Autoresearch SKILL.md rubric

11 criteria, 1 point each. Target: 11/11.

Each criterion lists what the SKILL.md must contain to earn the point. A grader reads `skills/autoresearch/SKILL.md` and scores 0 or 1 per criterion with a one-sentence justification. Half credit is not allowed — either the SKILL.md has it or it doesn't.

---

## C1. Mode parsing and routing

The skill recognizes three execution modes from arguments: `narrow`, `broad`, and a default (quality-sweep) fallback. Each new session records which mode it is in, and `resume` knows how to route back into that mode.

Pass if **all** of:
- Argument parsing names `narrow` and `broad` explicitly
- A `mode:` field appears in the session.md template
- Resume logic reads the mode and dispatches appropriately

## C2. Narrow: quantifiable goal specification

Narrow mode requires the user to define a goal that can be measured automatically. The skill blocks cycles from starting until the goal is defined with all four pieces of information.

Pass if the narrow-mode setup explicitly requires:
- A metric name (what is being measured)
- A measurement command (how to measure, returning a parseable value)
- A baseline value (captured before cycles start)
- A target value (a number or condition — "≥", "≤", "=")

## C3. Narrow: priority-ranked angles

The user proposes one or more angles (strategies) to hit the goal. If more than one is proposed, they must be explicitly ranked 1, 2, 3 before any cycle runs. The coordinator refuses to start cycles without explicit ranking and executes angles in priority order — angle 1 is exhausted before angle 2 is attempted.

Pass if **all** of:
- The skill calls out explicit ranking (e.g., "priority 1, 2, 3")
- The skill refuses to start without a ranked list when there are multiple angles
- Angle 1 is attempted before angle 2; angle 2 before angle 3

## C4. Narrow: goal-met termination

After each cycle the skill re-runs the measurement command, compares to the target, and stops if the target is met. If cycling has improved the metric but not reached the target, continue. If cycling regresses the metric, revert.

Pass if **all** of:
- Post-cycle re-measurement is explicit
- Early-stop condition when target met is explicit
- Regression check (metric worse than baseline) triggers revert

## C5. Broad: 3–5 diverse hypotheses

Broad mode generates between 3 and 5 hypotheses at the start. Fewer than 3 is rejected; more than 5 is pruned. Each hypothesis has a short name and a one-sentence hypothesis statement describing what it tries to prove.

Pass if **all** of:
- Count requirement (`min 3, max 5` or equivalent wording)
- Each hypothesis has a name + one-sentence statement
- Hypotheses are written out before any cycle runs

## C6. Broad: obvious + bold + creative categorization

At minimum one hypothesis is labelled **obvious** (the conventional fix), one **bold** (challenges a held assumption), and one **creative** (a lateral, outside-the-box approach). Additional categories like "adjacent" or "wildcard" are allowed but not required.

Pass if **all** of:
- The three labels `obvious`, `bold`, `creative` appear as required categories
- The skill instructs the Strategist to avoid making all hypotheses obvious variants
- Each hypothesis carries its category as a tag

## C7. Broad: independent tracks per hypothesis

Each hypothesis runs on its own isolated track. A track has its own git branch, its own cycles subdirectory, and its own results log. Findings from one track do not leak into another — each track starts from the base commit.

Pass if **all** of:
- Per-hypothesis branch naming scheme (e.g., `autoresearch/broad/<session>/h1`)
- Per-hypothesis cycles directory (e.g., `cycles/h1/001/`)
- Each track begins from the same base commit, not from the previous track's output

## C8. Broad: comparison + winner stage

After all tracks finish, the coordinator produces a side-by-side comparison and names a winner. The comparison is written to a file the user can read, and the losing tracks are preserved as branches (not deleted).

Pass if **all** of:
- An explicit "compare" stage after tracks complete
- Output artifact naming the winner and the reasoning
- Losing tracks are preserved (branches kept) rather than deleted

## C9. Clean-room + revert safety preserved in both modes

The Red → Green → Refactor information barriers still apply in narrow and broad modes. The revert procedure (refactor reverts first, then green, then hard-reset if needed) still applies in both modes.

Pass if **all** of:
- Clean-room rules section exists and is referenced from both mode sections
- Revert procedure is referenced from both mode sections
- Neither mode introduces a shortcut that bypasses these rules

## C10. Resumability covers mode + position

`resume` reads the session's mode and restarts at the right place: in narrow, the current angle; in broad, the current track + cycle. Interrupted mid-cycle re-runs that cycle from the beginning.

Pass if **all** of:
- Resume reads `mode` from session.md
- Narrow resume identifies current angle and next cycle number
- Broad resume identifies current track and next cycle number within that track

## C11. Versioning

The skill records its own version, stamps every new session with that version, and handles version drift on resume.

Pass if **all** of:
- `version:` field present in the SKILL.md YAML frontmatter using semver (MAJOR.MINOR.PATCH)
- `Skill version` field appears in the session.md template so new sessions stamp the installed version
- Resume reads the stamp and dispatches: same → continue; installed newer (PATCH/MINOR) → note and continue; installed newer (MAJOR) → warn and ask; installed older → refuse
- `version` is a recognized argument that prints the current skill version and stops

---

## Scoring

Total = sum of criteria. Pass = 11/11.

If a criterion is partially met, it scores 0. No partial credit. This keeps iterations honest.
