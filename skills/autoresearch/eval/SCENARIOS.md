# Eval scenarios

Sample inputs to sanity-check the skill. A grader is not required to run these — they exist so a human or a secondary agent can walk through and verify the skill gives sane answers.

## S1. Narrow — single angle

Input: `/autoresearch narrow ~/Work/api-service`

Interactive answers:
- Goal metric: `p99 latency`
- Measurement command: `make bench-p99`
- Baseline: `340ms`
- Target: `≤100ms`
- Angles: (only 1) "Reduce database round-trips on the hot path"

Expected: No ranking prompt (only one angle). Cycles begin. After each cycle, measurement is re-run. Stops if `≤100ms` hits.

## S2. Narrow — three angles, user ranks them

Input: `/autoresearch narrow ~/Work/api-service`

Interactive answers:
- Goal metric: `test coverage`
- Measurement command: `go test -cover ./... | tail -1`
- Baseline: `62%`
- Target: `≥80%`
- Angles:
  - A: "Add tests for uncovered error paths"
  - B: "Extract pure helpers from mega-functions so they can be tested in isolation"
  - C: "Generate property-based tests for core data structures"
- Ranking prompt: user answers `1=A, 2=B, 3=C`

Expected: Coordinator works A fully first, then B, then C. Goal met at any point stops execution. Unranked input is rejected.

## S3. Broad — new feature idea

Input: `/autoresearch broad ~/Work/cli-tool`

Aspiration: "Make this CLI dramatically faster to use every day."

Expected: Strategist proposes 5 hypotheses labelled:
- obvious: "Shell completion + better --help"
- adjacent: "A REPL mode that batches commands"
- bold: "Compile config to a single pre-parsed binary blob"
- creative: "Replace subcommands with a fuzzy natural-language router"
- wildcard: "Ship a local daemon so repeated invocations skip cold start"

Each hypothesis runs on its own branch `autoresearch/broad/cli-tool/h<N>`. After all tracks complete, a comparison document names a winner and the reasoning.

## S4. Resume — interrupted narrow mid-angle 2

Input: `/autoresearch resume api-service`

Expected: Reads `mode: narrow`, sees angle 1 complete, angle 2 at cycle 003 (no eval-results.md for 003), re-runs cycle 003 from the beginning of angle 2.

## S5. Resume — interrupted broad mid-track h3

Input: `/autoresearch resume cli-tool`

Expected: Reads `mode: broad`, sees h1, h2 complete, h3 at cycle 002 (interrupted). Checks out `autoresearch/broad/cli-tool/h3`, re-runs cycle 002.
