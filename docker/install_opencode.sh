#!/usr/bin/env bash
set -euo pipefail

echo "Installing opencode-ai (npm global)..."
npm install -g opencode-ai

echo "opencode-ai installed: $(which opencode-ai || echo 'not found')"

# Optional post-install hook: /usr/local/bin/post_install_opencode.sh
if [ -x /usr/local/bin/post_install_opencode.sh ]; then
	echo "Running post-install hook for opencode-ai"
	/usr/local/bin/post_install_opencode.sh
fi
