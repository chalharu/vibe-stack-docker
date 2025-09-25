#!/usr/bin/env bash
set -euo pipefail

echo "Installing claude-code (npm global)..."
npm install -g @anthropic-ai/claude-code

echo "claude-code installed: $(which claude || echo 'not found')"

# Optional post-install hook: /usr/local/bin/post_install_claude.sh
if [ -x /usr/local/bin/post_install_claude.sh ]; then
	echo "Running post-install hook for claude-code"
	/usr/local/bin/post_install_claude.sh
fi
