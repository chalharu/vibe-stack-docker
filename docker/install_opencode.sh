#!/usr/bin/env bash
set -euo pipefail

echo "Installing opencode-ai (npm global)..."
npm install -g opencode-ai

echo "opencode-ai installed: $(which opencode || echo 'not found')"

# Optional post-install hook: /usr/local/bin/post_install_opencode.sh
if [ -x /usr/local/bin/post_install_opencode.sh ]; then
	echo "Running post-install hook for opencode"
	/usr/local/bin/post_install_opencode.sh
fi
