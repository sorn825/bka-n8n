#!/bin/bash
# =============================================================================
# Restore TIVDB จาก encrypted backup เข้า postgres container บนเครื่องนี้
# Usage: ./restore.sh [file.dump.enc]
#   ถ้าไม่ระบุไฟล์ จะใช้ .dump.enc ล่าสุดใน folder นี้
# รันบน Ubuntu server โดยตรง ไม่ใช่จากเครื่อง remote
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: .env file not found at $ENV_FILE"
  echo "Copy .env.example to .env and fill in the required values"
  exit 1
fi

# shellcheck disable=SC1090
. "$ENV_FILE"

CONTAINER="postgres"
DB="TIVDB"
PG_USER="postgres"

# Resolve dump file
if [ -n "$1" ]; then
  DUMP_FILE="$1"
else
  DUMP_FILE=$(ls -t "$SCRIPT_DIR"/*.dump.enc 2>/dev/null | head -1)
fi

if [ -z "$DUMP_FILE" ] || [ ! -f "$DUMP_FILE" ]; then
  echo "Error: no .dump.enc file found. Pass a path or place a .dump.enc file in $SCRIPT_DIR"
  exit 1
fi

echo "Using: $DUMP_FILE"

# รอให้ postgres container พร้อม
echo "Checking postgres container..."
until docker exec "$CONTAINER" pg_isready -U "$PG_USER" > /dev/null 2>&1; do
  echo "Waiting for postgres..."
  sleep 2
done

echo "Dropping and recreating database $DB..."
docker exec "$CONTAINER" psql -U "$PG_USER" -c "DROP DATABASE IF EXISTS \"$DB\";"
docker exec -i "$CONTAINER" psql -U "$PG_USER" < "$SCRIPT_DIR/../init/init.sql"

echo "Restoring data..."
openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:"$BACKUP_PASSWORD" -in "$DUMP_FILE" \
  | docker exec -i "$CONTAINER" pg_restore -U "$PG_USER" -d "$DB" --no-owner --role="$PG_USER" --data-only 2>&1 \
  | grep -v "^$" || true

echo "Verifying row count..."
docker exec "$CONTAINER" psql -U "$PG_USER" -d "$DB" -c "SELECT COUNT(*) FROM property_listing;"

echo "Restore complete!"
