#!/bin/bash
set -euo pipefail

REPO="https://github.com/itoh-shun/mosaic-works.git"
INSTALL_DIR="${HOME}/.claude/skills/mosaic-works"
SKILL_LINK="${HOME}/.claude/skills/mosaic-orch"

echo "mosaic-orch installer"
echo "====================="

# Clone or update
if [ -d "$INSTALL_DIR" ]; then
  echo "Updating existing installation..."
  git -C "$INSTALL_DIR" pull --ff-only
else
  echo "Cloning mosaic-works..."
  git clone "$REPO" "$INSTALL_DIR"
fi

# Create symlink
ln -sfn "$INSTALL_DIR/skills/mosaic-orch" "$SKILL_LINK"

echo ""
echo "Done! mosaic-orch installed at $SKILL_LINK"
echo ""
echo "Restart Claude Code, then try:"
echo "  /mosaic-orch --list-workflows"
