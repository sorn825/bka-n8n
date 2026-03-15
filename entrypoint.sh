#!/bin/sh
# =============================================================================
# Docker entrypoint สำหรับ n8n container
# ไฟล์นี้รันอัตโนมัติภายใน container เมื่อทำ docker compose up
# ไม่ควรรันโดยตรงบนเครื่อง host
# =============================================================================

# 1. Import workflows จาก /workflows/ (mount จาก ./workflows ใน host)
n8n import:workflow --separate --input=/workflows/ 2>/dev/null || true

# 2. Start n8n ใน background เพื่อให้ทำ owner setup ต่อได้
n8n start &
N8N_PID=$!

# 3. รอจนกว่า n8n จะพร้อมรับ request
echo "Waiting for n8n to be ready..."
until curl -sf http://localhost:5678/healthz > /dev/null 2>&1; do
  sleep 2
done
echo "n8n is ready."

# 4. สร้าง owner account อัตโนมัติ (ค่ามาจาก .env ผ่าน docker-compose)
#    - 200: สร้างสำเร็จ (ครั้งแรก)
#    - 404: มี owner อยู่แล้ว ข้ามได้
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

# 5. รอให้ n8n process ทำงานต่อไป (ไม่ให้ container ปิด)
wait $N8N_PID
