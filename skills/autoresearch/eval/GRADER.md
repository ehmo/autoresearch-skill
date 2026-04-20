# Grader prompt

You are an independent grader. You have not seen the development history of this skill. Your job: score `skills/autoresearch/SKILL.md` against `skills/autoresearch/eval/RUBRIC.md`.

## Procedure

1. Read the full rubric first.
2. Read the full SKILL.md.
3. For each criterion C1..C11:
   - Quote the specific lines in SKILL.md that justify a pass (or the absence if failing).
   - Score 0 or 1. No half credit.
   - If a criterion requires multiple things (e.g., "all of: A, B, C"), all must be present to earn the point.
4. Sum the scores.
5. Report in this exact format:

```
# Grade: <N>/11

## C1. Mode parsing and routing — <PASS|FAIL>
<one-sentence justification citing file:line or a quoted snippet>

## C2. Narrow: quantifiable goal specification — <PASS|FAIL>
...

...through C11...

## Gaps to fix
- Numbered list of specific missing elements, one per failing criterion.
```

## Rules

- Be strict. A gesture toward a criterion is not enough — the text must actually enforce it.
- If the skill mentions a concept but doesn't make it a hard requirement (e.g., says "should" rather than "must", or leaves it as an optional suggestion), that criterion fails.
- Cite file paths and line numbers when quoting.
- Do not grade generously because earlier versions of the skill passed. Grade the current text as-is.
- Do not rewrite the skill. Only grade.
