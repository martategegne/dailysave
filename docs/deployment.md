# DailySave Production Deployment Manual

This guide covers deploying DailySave in production with Docker, PostgreSQL 18, Nginx reverse proxy, and SSL/TLS.

---

## 1. Production Architecture

```
[Internet Client]
       │
       ▼ (HTTPS :443 / TLS 1.3)
 ┌─────────────┐
 │ Nginx Proxy │─── Static Files (Flutter Web) ──► [/usr/share/nginx/html]
 └──────┬──────┘
        │ (HTTP :4000)
        ▼
 ┌──────────────┐
 │ Node Backend │ (Native node:http, Non-root user)
 └──────┬───────┘
        │ (TCP :5432)
        ▼
 ┌──────────────┐
 │ PostgreSQL18 │ (Persistent Volume: postgres_data)
 └──────────────┘
```

---

## 2. Server Prerequisites

- Linux Server (Ubuntu 22.04 LTS or 24.04 LTS recommended).
- Docker Engine 24+ and Docker Compose v2+.
- Domain Name pointed to server IP (e.g., `dailysave.et`).
- Valid SSL certificates (via Let's Encrypt / Certbot).

---

## 3. Step-by-Step Deployment

### Step 1: Clone Repository
```bash
git clone https://github.com/your-org/dailysave.git
cd dailysave
```

### Step 2: Configure Production Environment
Copy the example production environment file:
```bash
cp backend/.env.production.example backend/.env.production
```
Generate high-entropy secrets:
```bash
openssl rand -base64 48 # For JWT_ACCESS_SECRET
openssl rand -base64 48 # For JWT_REFRESH_SECRET
openssl rand -base64 32 # For DB_PASSWORD
```
Fill in the values in `backend/.env.production`.

### Step 3: Build Flutter Web Production Bundle
```bash
flutter build web --release --pwa-strategy=none
# Output located at: build/web
```

### Step 4: Launch Containers with Docker Compose
```bash
docker compose up -d --build
```

### Step 5: Verify Deployment
```bash
# Check container status
docker compose ps

# Check backend health
curl -f https://dailysave.et/health

# Tail backend logs
docker compose logs -f backend
```

---

## 4. Automated Database Backups

A cron job can be configured to run daily backups:
```bash
# Add to crontab (runs at 02:00 AM daily)
0 2 * * * /opt/dailysave/backend/scripts/backup.sh >> /var/log/dailysave_backup.log 2>&1
```

### Manual Backup:
```bash
./backend/scripts/backup.sh
```

### Manual Restore:
```bash
./backend/scripts/restore.sh /var/backups/dailysave/dailysave_db_YYYYMMDD_HHMMSS.sql.gz
```
