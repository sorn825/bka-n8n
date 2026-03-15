#!/bin/bash
# Restore TIVDB to remote postgres container
# Usage: ./restore.sh [dump_file]
#   If no file specified, uses the latest .dump file in the same folder

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: .env file not found at $ENV_FILE"
  echo "Copy .env.example to .env and fill in REMOTE_HOST"
  exit 1
fi

# shellcheck disable=SC1090
. "$ENV_FILE"

REMOTE="ubuntu@${SUBDOMAIN}.${DOMAIN_NAME}"
CONTAINER="postgres"
DB="TIVDB"
PG_USER="postgres"

# Resolve dump file
if [ -n "$1" ]; then
  DUMP_FILE="$1"
else
  DUMP_FILE=$(ls -t "$SCRIPT_DIR"/*.dump 2>/dev/null | head -1)
fi

if [ -z "$DUMP_FILE" ] || [ ! -f "$DUMP_FILE" ]; then
  echo "Error: no dump file found. Pass a path or place a .dump file in $SCRIPT_DIR"
  exit 1
fi

echo "Using dump file: $DUMP_FILE"
echo "Uploading to $REMOTE..."

# Upload dump to remote
scp "$DUMP_FILE" "$REMOTE:/tmp/restore.dump"

# Restore: drop existing data, recreate tables, restore
ssh "$REMOTE" bash <<EOF
  set -e

  # Wait for postgres container to be up
  echo "Checking postgres container..."
  until docker exec $CONTAINER pg_isready -U $PG_USER > /dev/null 2>&1; do
    echo "Waiting for postgres..."
    sleep 2
  done

  echo "Dropping and recreating database $DB..."
  docker exec $CONTAINER psql -U $PG_USER -c "DROP DATABASE IF EXISTS \"$DB\";"
  docker exec -i $CONTAINER psql -U $PG_USER < ~/bka-n8n/init/init.sql

  echo "Restoring data..."
  cat /tmp/restore.dump | docker exec -i $CONTAINER pg_restore -U $PG_USER -d $DB --no-owner --role=$PG_USER --data-only 2>&1 | grep -v "^$" || true

  echo "Verifying row count..."
  docker exec $CONTAINER psql -U $PG_USER -d $DB -c "SELECT COUNT(*) FROM property_listing;"

  rm /tmp/restore.dump
  echo "Restore complete!"
EOF
