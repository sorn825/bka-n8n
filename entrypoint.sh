#!/bin/sh

# Import workflows
n8n import:workflow --separate --input=/workflows/ 2>/dev/null || true

# Start n8n in background
n8n start &
N8N_PID=$!

# Wait for n8n to be ready
echo "Waiting for n8n to be ready..."
until curl -sf http://localhost:5678/healthz > /dev/null 2>&1; do
  sleep 2
done
echo "n8n is ready."

# Try to setup owner account
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:5678/rest/owner/setup \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"${N8N_OWNER_EMAIL}\",\"firstName\":\"${N8N_OWNER_FIRSTNAME}\",\"lastName\":\"${N8N_OWNER_LASTNAME}\",\"password\":\"${N8N_OWNER_PASSWORD}\"}")

if [ "$HTTP_STATUS" = "200" ]; then
  echo "Owner account created successfully."
elif [ "$HTTP_STATUS" = "404" ]; then
  echo "Owner account already exists, skipping setup."
else
  echo "Owner setup returned status: $HTTP_STATUS"
fi

# Wait for n8n to exit
wait $N8N_PID
