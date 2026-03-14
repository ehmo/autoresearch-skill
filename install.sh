#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

# Check prerequisites
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "Error: Claude Code config directory not found at $CLAUDE_DIR"
    echo "Install Claude Code first, or export CLAUDE_DIR to your config path."
    exit 1
fi

if [ ! -d "$SCRIPT_DIR/skills/autoresearch" ]; then
    echo "Error: skills/autoresearch not found. Are you running from the right directory?"
    exit 1
fi

echo "Installing autoresearch to $CLAUDE_DIR ..."

# Symlink skill (remove first for GNU/BSD compatibility)
mkdir -p "$CLAUDE_DIR/skills"
rm -f "$CLAUDE_DIR/skills/autoresearch"
ln -s "$SCRIPT_DIR/skills/autoresearch" "$CLAUDE_DIR/skills/autoresearch"
if [ ! -L "$CLAUDE_DIR/skills/autoresearch" ]; then
    echo "Error: failed to create skill symlink"
    exit 1
fi
echo "  skill linked"

# Symlink command
mkdir -p "$CLAUDE_DIR/commands"
rm -f "$CLAUDE_DIR/commands/autoresearch.md"
ln -s "$SCRIPT_DIR/commands/autoresearch.md" "$CLAUDE_DIR/commands/autoresearch.md"
if [ ! -L "$CLAUDE_DIR/commands/autoresearch.md" ]; then
    echo "Error: failed to create command symlink"
    exit 1
fi
echo "  command linked"

mkdir -p "$SCRIPT_DIR/sessions"

echo ""
echo "Done. Usage:"
echo "  /autoresearch ~/path/to/project"
echo "  /autoresearch resume"
echo "  /autoresearch status"
