#!/bin/bash
set -e

# Configuration
DB_PATH="$HOME/.openclaw/sandboxes.db"
mkdir -p "$(dirname "$DB_PATH")"

# Initialize Schema
init_db() {
    sqlite3 "$DB_PATH" <<EOF
CREATE TABLE IF NOT EXISTS sandboxes (
    id TEXT PRIMARY KEY,
    name TEXT UNIQUE,
    stack TEXT,
    port INTEGER,
    tunnel_url TEXT,
    volume_path TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
EOF
}

# Helper to run queries
query_db() {
    local query="$1"
    shift
    if [ $# -eq 0 ]; then
        sqlite3 "$DB_PATH" "$query"
    else
        # Use python for parameterized queries
        DB_PATH="$DB_PATH" python3 - "$query" "$@" <<'EOF'
import sqlite3
import os
import sys

db_path = os.environ['DB_PATH']
query = sys.argv[1]
params = sys.argv[2:]

conn = sqlite3.connect(db_path)
cursor = conn.cursor()
try:
    cursor.execute(query, params)
    for row in cursor.fetchall():
        print("|".join(str(v) if v is not None else "" for v in row))
    conn.commit()
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
finally:
    conn.close()
EOF
    fi
}

# Run init if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_db
    echo "Database initialized at $DB_PATH"
fi
