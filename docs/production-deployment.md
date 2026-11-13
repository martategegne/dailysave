# DailySave Production Deployment Manual & Operations Runbook

This runbook provides complete, step-by-step execution instructions for deploying DailySave's public website, Flutter Web application, native Node.js backend, and PostgreSQL database.

---

## 1. Prerequisites Checklist

Ensure the following tools and accounts are ready before executing deployments:
* **Node.js:** v20+ (v24 LTS recommended)
* **Flutter SDK:** 3.x with web build tools
* **Git:** Installed and authenticated with GitHub/GitLab
* **Cloud Accounts:**
  * [Cloudflare](https://dash.cloudflare.com/) (For DNS, SSL, and Cloudflare Pages)
  * [Render](https://render.com/) or [Koyeb](https://www.koyeb.com/) (For Backend Web Service)
  * [Neon](https://neon.tech/) or [Supabase](https://supabase.com/) (For Managed PostgreSQL 18)

---

## 2. Step 1: Deploy PostgreSQL Production Database

1. Create a new PostgreSQL instance on **Neon** or **Supabase** in the `eu-central-1` (Frankfurt) region for lowest latency to Ethiopia.
2. Retrieve the connection string:
   ```
   postgres://dailysave_owner:<PASSWORD>@ep-example.eu-central-1.aws.neon.tech/dailysave_prod?sslmode=require
   ```
3. Run migrations from your terminal against the production database:
   ```bash
   cd backend
   DB_HOST=ep-example.eu-central-1.aws.neon.tech \
   DB_PORT=5432 \
   DB_NAME=dailysave_prod \
   DB_USER=dailysave_owner \
   DB_PASSWORD=<PASSWORD> \
   DB_SSL=true \
   node src/database/migrate.js
   ```
4. Verify output logs confirm all 6 versioned migrations (001 through 006) were successfully applied.

---

## 3. Step 2: Deploy Backend REST API Service

### Option A: Turnkey Render Blueprint Deployment (Zero Configuration)
1. In the Render Dashboard, click **New > Blueprint**.
2. Connect your `dailysave` repository.
3. Render reads `render.yaml` automatically and configures the `dailysave-api` service and environment variables.
4. Set the custom domain in Render settings: `api.dailysave.et`.

### Option B: Docker Container Deployment (Koyeb / Fly.io / VPS)
```bash
# Build production Docker image
docker build -t dailysave-api:latest -f backend/Dockerfile backend

# Run container with production environment variables
docker run -d \
  --name dailysave-api \
  -p 4000:4000 \
  --env-file backend/.env.production \
  --restart unless-stopped \
  dailysave-api:latest
```

---

## 4. Step 3: Deploy Marketing Website (`www.dailysave.et`)

The public static website lives in the `website/` directory.

### Deploying via Cloudflare Pages:
1. In Cloudflare Dashboard, go to **Workers & Pages > Create application > Pages > Connect to Git**.
2. Select the `dailysave` repository.
3. Set the build configuration:
   * **Project Name:** `dailysave-website`
   * **Framework Preset:** `None`
   * **Build Command:** *(Leave empty, static files)*
   * **Build Output Directory:** `website`
4. Click **Save and Deploy**.
5. Under **Custom Domains**, add `www.dailysave.et`.

---

## 5. Step 4: Deploy Flutter Web Application (`app.dailysave.et`)

### Compile Production Web Build:
```powershell
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.dailysave.et/api/v1
```

### Deploying via Cloudflare Pages:
1. In Cloudflare Dashboard, create a second Pages project:
   * **Project Name:** `dailysave-app`
   * **Framework Preset:** `Flutter`
   * **Build Command:** `flutter build web --release --dart-define=API_BASE_URL=https://api.dailysave.et/api/v1`
   * **Build Output Directory:** `build/web`
2. Under **Custom Domains**, bind `app.dailysave.et`.
3. Verify that `_headers` and `_redirects` are served:
   * Test SPA deep linking by navigating directly to `https://app.dailysave.et/transactions` (should return 200, not 404).
   * Inspect response headers for `Strict-Transport-Security` and `X-Frame-Options: DENY`.

---

## 6. Step 5: Automated Production Verification

Run the bundled verification suite to validate all layers:
```bash
node scripts/verify-production.js
```

### Verification Criteria:
* [x] Static marketing assets verified (all 14 HTML pages, CSS, JS, blog articles).
* [x] Private dashboard robots guardrail (`noindex, nofollow` and `Disallow: /`).
* [x] Managed PostgreSQL connectivity and migration schema verified.
* [x] REST API `/health` endpoint responds with HTTP 200 OK.
* [x] SSL/TLS handshake enforces TLS 1.2+ with Full (Strict) Cloudflare encryption.
