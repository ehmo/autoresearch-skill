# autoresearch

Autonomous codebase improvement. Three independent teams run against your code in a loop: one finds problems, one fixes them, one simplifies what's left. Everything happens on a branch. Nothing touches main until you merge.

Current skill version: **2.0.0** ([changelog](skills/autoresearch/CHANGELOG.md)). Run `/autoresearch version` to print the version of the installed skill.

## Three modes

- **narrow** — you have a measurable goal (p99 latency, coverage %, bundle size, lint count). You propose one or more angles and rank them. Autoresearch works angle 1 first, re-measures after every cycle, and stops when the target hits.
- **broad** — you have an aspiration without a number. Autoresearch generates 3–5 diverse hypotheses — at minimum one obvious, one bold (challenges an assumption), and one creative (outside-the-box) — runs each on its own branch, and compares results to name a winner.
- **sweep** (default) — general quality improvement: bug hunting, refactoring, coverage gaps. The original loop.

## Where this came from

Andrej Karpathy's [autoresearch](https://github.com/karpathy/autoresearch) showed that you can let an agent modify training code, run experiments, keep what works, and throw away what doesn't. You go to sleep, you wake up to a better model. [pi-autoresearch](https://github.com/davebcn87/pi-autoresearch) and [drivelineresearch/autoresearch-claude-code](https://github.com/drivelineresearch/autoresearch-claude-code) generalized this beyond ML to any codebase.

This project uses up to three teams with information barriers between them instead of a single agent. Each team starts from a clean context and only sees what the coordinator passes to it. The team fixing bugs doesn't know how they were found, and the team simplifying code doesn't know what was broken.

## How a cycle works

Each cycle runs three stages:

1. The Red team reads the codebase and writes a findings report with file paths, line numbers, and descriptions of what's wrong. It doesn't modify anything. In narrow mode the Red team is scoped to the current angle; in broad mode it is scoped to the current hypothesis.

2. The coordinator strips the analysis methodology from the findings and passes only the "what and where" to the Green team. The Green team fixes issues one at a time, running tests after each commit.

3. The Refactor team gets the codebase in its current state with no context about what was found or fixed. It picks 3–5 simplifications, runs tests after each change.

The coordinator verifies tests, logs results, and starts the next cycle.

In narrow mode the coordinator re-measures the goal metric after each cycle and stops the whole session once the target is hit. In broad mode the coordinator runs all tracks sequentially (or in parallel if configured), then writes a comparison document and names a winner.

## What to expect

On a 25K-line Go project, five cycles produced 49 commits on a feature branch: 31 bug fixes (8 breaking core functionality), 6 new test suites, 5 performance optimizations replacing N+1 query patterns, and about 100 lines of dead code removed.

Your results will depend on the size, test coverage, and existing quality of the target project. Codebases with good test coverage get the most value since the Green team can verify its fixes. Projects with few tests will see the Red team flag missing coverage as a priority.

## Install

### Claude Code

```bash
git clone git@github.com:ehmo/autoresearch.git
cd autoresearch
./install.sh
```

Creates symlinks in `~/.claude/` for the skill and slash command. The script checks that Claude Code is installed first.

To use a non-default config directory, export `CLAUDE_DIR` before running:

```bash
export CLAUDE_DIR=/custom/path
./install.sh
```

### Codex

Add the contents of `agents/codex.md` to your project's AGENTS.md or equivalent instruction file.

### Other agents

The full protocol is in `skills/autoresearch/SKILL.md`. It's plain markdown. Drop it into whatever instruction format your agent uses.

## Usage

Narrow mode (drive a specific metric):

```
/autoresearch narrow ~/path/to/project
```

You'll be asked for a metric, a measurement command, a baseline, and a target. Then for one or more angles — and if you give more than one, you'll be asked to rank them 1, 2, 3 before cycles start.

Broad mode (diverge and compare):

```
/autoresearch broad ~/path/to/project
```

You'll be asked for an aspiration ("make the CLI faster to use every day"). The coordinator generates 3–5 diverse hypotheses, shows them to you for approval, then runs each on its own branch. At the end you get a comparison document and a winner.

Sweep mode (default, general quality):

```
/autoresearch ~/path/to/project
```

The coordinator detects your stack, finds the test command, creates a branch, and starts running cycles. It asks for confirmation before modifying anything.

Resume after a break (mode is read from the session file):

```
/autoresearch resume
/autoresearch resume myproject
```

Check progress:

```
/autoresearch status
```

### Configuration

Create `.autoresearch.yml` in your project root to customize behavior:

```yaml
# Override auto-detected test command
test_command: "make test-unit"

# Limit what the teams can see and modify
include:
  - "src/"
  - "lib/"
exclude:
  - "vendor/"
  - "generated/"

# Stop after this many cycles (default: runs until diminishing returns)
max_cycles: 10

# Skip the refactor stage
teams:
  - red
  - green
```

Without a config file, autoresearch detects everything automatically and runs all three teams.

## How sessions are stored

Session data lives in `sessions/<project-name>/` within the autoresearch repo:

```
sessions/myproject/
  session.md        # What's been done, what's left to try
  results.tsv       # One row per team per cycle
  ideas.md          # Findings deferred for later cycles
  cycles/
    001/
      red-findings.md
      green-patch.md
      refactor-patch.md
      eval-results.md
```

The `sessions/` directory is gitignored.

## Requirements

- An AI coding agent with sub-agent support for full clean-room separation (Claude Code), or a single-agent setup with reduced separation (Codex, others)
- Git
- A test suite that exits non-zero on failure

Stack detection covers Go, Node/TypeScript, Rust, Python, Java/Kotlin, Ruby, PHP, Elixir, and anything with a Makefile.

## Limitations

Works best on projects with decent test coverage. Without tests, the Green team has no way to verify its fixes don't break things.

Large monorepos benefit from the `include`/`exclude` config to keep the teams focused on relevant code.

The information barriers between teams are enforced by sub-agent context separation, not cryptography. Each sub-agent starts fresh with only the information the coordinator passes to it.

Not tested on Windows outside of WSL. The install script uses symlinks which require elevated permissions on native Windows.

## Uninstall

```bash
./uninstall.sh
```

Removes symlinks from `~/.claude/`. Session data in `sessions/` is kept.

## License

MIT
