# Autoresearch for Codex

Add this to your project's AGENTS.md or equivalent instruction file.

Note: Codex runs as a single agent, so the clean-room separation between phases is weaker than in multi-agent setups like Claude Code. You'll have full context of what you found when you start fixing things. The protocol still works because the phased approach forces structured thinking, but the independent-perspective benefit is reduced.

---

## Protocol

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

Make one change at a time. Run tests. Commit or revert. Pick the 3-5 most worthwhile simplifications.

### After each cycle

Run the test suite. If it passes, start the next cycle. If it fails, revert until it passes again. Stop when the simplification phase can't find anything worth changing.
