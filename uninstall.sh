#!/bin/bash
set -e

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

echo "Removing autoresearch from $CLAUDE_DIR ..."

if [ -L "$CLAUDE_DIR/skills/autoresearch" ]; then
    rm "$CLAUDE_DIR/skills/autoresearch"
    echo "  skill removed"
else
    echo "  skill symlink not found, skipping"
fi

if [ -L "$CLAUDE_DIR/commands/autoresearch.md" ]; then
    rm "$CLAUDE_DIR/commands/autoresearch.md"
    echo "  command removed"
else
    echo "  command symlink not found, skipping"
fi

echo "Done. Session data in sessions/ is preserved."
