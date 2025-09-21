#!/usr/bin/env bash
set -euo pipefail

echo "Installing vibe-kanban (npm global)..."
npm install -g vibe-kanban

echo "vibe-kanban installed: $(which vibe-kanban || echo 'not found')"

# Optional post-install hook: /usr/local/bin/post_install_vibe.sh
if [ -x /usr/local/bin/post_install_vibe.sh ]; then
	echo "Running post-install hook for vibe-kanban"
	/usr/local/bin/post_install_vibe.sh
fi
