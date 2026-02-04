#!/usr/bin/env python3
import json
import sys

# Read config from stdin
config = json.load(sys.stdin)

# Update workspace access
config['agents']['defaults']['sandbox']['workspaceAccess'] = 'rw'

# Write to stdout
json.dump(config, sys.stdout, indent=2)
