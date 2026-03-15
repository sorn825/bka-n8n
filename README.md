# bka-n8n

ระบบ workflow automation ด้วย n8n รันบน Docker Compose พร้อม HTTPS อัตโนมัติ, PostgreSQL และ FlareSolverr สำหรับ scraping เว็บที่มีการป้องกัน Cloudflare

## โครงสร้างโปรเจกต์

```
bka-n8n/
├── docker-compose.yaml          # ไฟล์หลักสำหรับรัน services ทั้งหมด
├── .env                         # ค่า config และ secrets (ไม่อยู่ใน git)
├── .env.example                 # ตัวอย่าง .env สำหรับ setup ใหม่
│
├── Dockerfile_n8n               # n8n + Python 3 + pandas/psycopg2/openpyxl
├── Dockerfile_postgres          # PostgreSQL 16 + Thai locale (th_TH.UTF-8)
├── Dockerfile_flaresolverr      # FlareSolverr + Express wrapper
├── entrypoint.sh                # startup script: import workflows + auto-create owner account
│
├── init/
│   └── init.sql                 # สร้าง database TIVDB และ table property_listing
│
├── workflows/                   # n8n workflow files (import อัตโนมัติตอน start)
│
├── local-files/
│   ├── scripts/                 # Python scripts (mount เข้า n8n container ที่ /files/scripts)
│   └── excel/                   # ไฟล์ Excel output (mount เข้า n8n container ที่ /files/excel)
│
└── warpper/                     # Express wrapper สำหรับ FlareSolverr
    ├── wrapper.js               # รับ request → FlareSolverr → filter HTML ด้วย CSS selector
    └── package.json
```

## Services

| Service | คำอธิบาย | Port |
|---|---|---|
| **traefik** | Reverse proxy + TLS (Let's Encrypt) | 80, 443 |
| **n8n** | Workflow automation | 5678 (ผ่าน Traefik) |
| **postgres** | ฐานข้อมูล PostgreSQL 16 (Thai locale) | 5432 |
| **flaresolverr** | Bypass Cloudflare พร้อม Express wrapper | 8191, 3000 |

## การติดตั้ง

### 1. Clone repo

```bash
git clone https://github.com/sorn825/bka-n8n.git
cd bka-n8n
```

### 2. ตั้งค่า .env

```bash
cp .env.example .env
```

แก้ค่าใน `.env` ให้ครบ:

```env
DOMAIN_NAME=example.com
SUBDOMAIN=n8n
GENERIC_TIMEZONE=Asia/Bangkok
SSL_EMAIL=your-email@example.com
POSTGRES_PASSWORD=your_strong_password
N8N_OWNER_EMAIL=admin@example.com
N8N_OWNER_PASSWORD=your_strong_password
N8N_OWNER_FIRSTNAME=Admin
N8N_OWNER_LASTNAME=User
```

### 3. ตั้ง permission สำหรับ folder output

```bash
chmod 777 local-files/excel
```

> จำเป็นเพื่อให้ n8n container (user `node`) เขียนไฟล์ Excel ได้

### 4. สร้าง external volume สำหรับ TLS certificate

```bash
docker volume create traefik_letsencrypt_permanent
```

> ป้องกัน certificate หายเมื่อทำ `docker compose down -v` (Let's Encrypt จำกัด 5 cert ต่อ 7 วัน)

### 5. รัน

```bash
docker compose up -d
```

n8n จะพร้อมใช้งานที่ `https://<SUBDOMAIN>.<DOMAIN_NAME>`

- Workflows ใน folder `workflows/` จะถูก import อัตโนมัติทุกครั้งที่ start
- Owner account จะถูกสร้างอัตโนมัติ ไม่ต้องผ่าน setup wizard

## FlareSolverr Wrapper

`warpper/wrapper.js` เป็น Express server ที่รันคู่กับ FlareSolverr (port 3000) ทำหน้าที่:

- รับ request เหมือน FlareSolverr API ปกติ
- เพิ่ม field `selector` (CSS selector) เพื่อ filter เฉพาะส่วนที่ต้องการออกจาก HTML
- ลบ elements ที่ไม่จำเป็น (img, svg, script, style) เพื่อลดขนาด response

**ตัวอย่าง request:**
```json
{
  "cmd": "request.get",
  "url": "https://example.com",
  "selector": ".listing-card"
}
```

## Notes

- `traefik_data/` และ `local-files/excel/` ไม่อยู่ใน git (เก็บแค่ `.gitkeep`)
- ไฟล์ `.env` ไม่อยู่ใน git ห้าม commit โดยเด็ดขาด
