#!/usr/bin/env python3
"""
Prepare k8s manifests for kind smoke test.
- Drops leading PVC document (if present)
- Replaces ghcr.io image references with IMAGE env var
- Converts persistentVolumeClaim -> emptyDir for kind
"""
import os
import re
import sys

IMAGE = os.environ.get('IMAGE')
if not IMAGE:
    print('ERROR: IMAGE environment variable not set', file=sys.stderr)
    sys.exit(2)

in_path = 'k8s/vibe-kanban-deployment.yaml'
out_path = 'k8s/vibe-kanban-deployment-applied.yaml'

with open(in_path, 'r', encoding='utf-8') as f:
    text = f.read()

# If there's a leading PVC document, drop it (keep remaining docs)
if '---' in text:
    parts = text.split('---', 1)
    text = parts[1].lstrip('\n')

# Replace any ghcr.io image reference with the test image
text = re.sub(r'ghcr\.io/[^:\s]+/[^:\s]+:[^\s\n]+', IMAGE, text)

# Convert persistentVolumeClaim + claimName -> emptyDir: {}
pattern = re.compile(r'(?m)^(?P<indent>[ \t]*)persistentVolumeClaim:[ \t]*\n(?P<indent2>[ \t]*)claimName:[^\n]*\n?')
text = pattern.sub(lambda m: f"{m.group('indent')}emptyDir: {{}}\n", text)

with open(out_path, 'w', encoding='utf-8') as f:
    f.write(text)

print(f'Wrote {out_path}')
