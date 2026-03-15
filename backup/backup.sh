#!/bin/bash
# =============================================================================
# Dump และ encrypt ฐานข้อมูล TIVDB จาก remote server
# Usage: ./backup.sh
# Output: backup/TIVDB_YYYYMMDD_HHMMSS.dump.enc (encrypted)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: .env file not found at $ENV_FILE"
  exit 1
fi

# shellcheck disable=SC1090
. "$ENV_FILE"

REMOTE="ubuntu@${SUBDOMAIN}.${DOMAIN_NAME}"
CONTAINER="postgres"
DB="TIVDB"
PG_USER="postgres"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT="$SCRIPT_DIR/TIVDB_${TIMESTAMP}.dump.enc"

echo "Dumping $DB from $REMOTE..."
ssh "$REMOTE" "docker exec $CONTAINER pg_dump -U $PG_USER -d $DB -Fc" \
  | openssl enc -aes-256-cbc -pbkdf2 -pass pass:"$BACKUP_PASSWORD" \
  > "$OUTPUT"

echo "Backup saved: $OUTPUT"
