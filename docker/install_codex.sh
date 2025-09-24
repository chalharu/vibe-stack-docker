#!/usr/bin/env bash
set -euo pipefail

echo "Installing codex (npm global)..."
npm install -g @openai/codex

echo "codex installed: $(which codex || echo 'not found')"

# Optional post-install hook: /usr/local/bin/post_install_codex.sh
if [ -x /usr/local/bin/post_install_codex.sh ]; then
	echo "Running post-install hook for codex"
	/usr/local/bin/post_install_codex.sh
fi
