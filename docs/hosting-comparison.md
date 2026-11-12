# Production Hosting & Cloud Provider Evaluation

This document presents a comprehensive, objective technical evaluation of cloud hosting providers for DailySave across frontend static hosting, containerized backend execution, and managed PostgreSQL databases.

---

## 1. Hosting Architecture Overview

```
                                +---------------------------+
                                |      Internet Users       |
                                +-------------+-------------+
                                              |
                        +---------------------+---------------------+
                        |                                           |
                        v                                           v
         +-----------------------------+             +-----------------------------+
         |     www.dailysave.et        |             |      app.dailysave.et       |
         |    (Marketing Website)      |             |    (Flutter Web SPA PWA)    |
         |   Host: Cloudflare Pages    |             |   Host: Cloudflare Pages    |
         +-----------------------------+             +--------------+--------------+
                                                                    |
                                                                    | API Requests
                                                                    v
                                                     +-----------------------------+
                                                     |      api.dailysave.et       |
                                                     |  (Native Node.js Backend)   |
                                                     |    Host: Render / Koyeb     |
                                                     +--------------+--------------+
                                                                    |
                                                                    | SSL Connection Pool
                                                                    v
                                                     +-----------------------------+
                                                     |    Managed PostgreSQL 18    |
                                                     |     Host: Neon / Supabase   |
                                                     +-----------------------------+
```

---

## 2. Frontend & Static Hosting Comparison

| Provider | Free Tier Limits | Bandwidth / mo | Build Limits | Inactivity Sleep | Custom Domains & SSL | Commercial Use | Recommended Role |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Cloudflare Pages** | **Unlimited** static requests & sites | **Unlimited** | 500 builds / mo | **None (Always instant on Edge)** | Unlimited free custom domains, automated Universal SSL | Permitted on Free tier | **Primary Choice (Frontend & Marketing)** |
| **Netlify** | 100 GB bandwidth, 1 site team | 100 GB / mo | 300 build mins / mo | None | 1 custom domain with Let's Encrypt SSL | Permitted on Free tier | Secondary alternative |
| **Vercel** | 100 GB bandwidth, non-commercial focus | 100 GB / mo | 6,000 build mins / mo | None | Custom domains with SSL | Free tier strictly non-commercial | Not recommended for commercial financial apps |
| **GitHub Pages** | 1 GB repository size, 100 GB bandwidth | 100 GB / mo | Standard Actions limits | None | 1 custom domain, Enforce HTTPS | Open-source friendly | Backup documentation mirror |

### Selection Rationale: Cloudflare Pages
* **Zero cold starts:** Static HTML, WASM, and compiled JS assets are cached across 300+ edge data centers worldwide.
* **Unlimited bandwidth:** Eliminates financial exposure to bandwidth overage charges.
* **Direct Git Integration:** Automatic preview builds on Pull Requests and atomic production deployments on `main`.

---

## 3. Backend Execution Hosting Comparison

| Provider | Free Tier Specs | Inactivity / Sleep Policy | Cold Start Latency | Outbound Bandwidth | SSL & Health Checks | Commercial Use | Verdict |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Render** | 512 MB RAM, 0.1 vCPU, 750 free instance hrs/mo | **Spins down after 15 mins of inactivity** | ~50 seconds when waking up | 100 GB / mo | Automated Let's Encrypt SSL, native `/health` check | Permitted | Viable with keep-alive cron |
| **Koyeb** | 512 MB RAM, 0.1 vCPU (Nano instance) | **No idle spin down on free instance** | 0 seconds (Always running) | 5 GB / mo | Free custom domain & SSL | Permitted | Excellent for zero-latency free backend |
| **Fly.io** | Up to 3 shared-cpu-1x 256MB VMs (trial limits apply) | Configurable auto-stop / auto-start | ~1.5 seconds | 100 GB / mo | Included | Permitted | Recommended for low-latency multi-region |
| **Railway** | \$5 one-time credit or pay-per-use (\$5/mo min) | No idle sleep while credits remain | 0 seconds | 100 GB / mo | Included | Permitted | High reliability, low cost paid tier |

### Selection Rationale: Render / Koyeb
* **Render:** Selected for the primary Blueprint (`render.yaml`) due to turnkey zero-configuration deployment of both the web service and database.
* **Cold-start mitigation:** Keep-alive ping jobs (e.g., UptimeRobot or Cron monitoring `/health` every 10 minutes) prevent Render web services from idling.

---

## 4. Managed PostgreSQL Database Comparison

| Provider | Free Storage | Active Connections | Auto-Pause / Inactivity Policy | Backup & Recovery | Connection Pooling | Financial Reliability Rating |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Neon** | 500 MB storage | Up to 10,000 via PgBouncer | Compute suspends after 5 mins of inactivity; **resumes in ~500ms** | Point-in-time recovery (branching) | Built-in PgBouncer pooling | **High (9.5/10)** |
| **Supabase** | 500 MB storage | Direct 60, Pooler 200 | **Pauses entirely after 7 days of inactivity**; manual dashboard unpause required | Daily automated backups | Built-in Supavisor | **Medium-High (8.5/10)** (Risk of 7-day dormancy pause) |
| **Render Postgres** | 1 GB storage | 97 connections | **Free database deleted after 90 days** (\$7/mo afterward) | Manual pg_dump | None built-in | **Low for Free (Must upgrade after 90 days)** |

### Selection Rationale: Neon
* **No dormancy deletion:** Neon preserves database schemas and storage indefinitely; only the compute layer suspends, auto-resuming on incoming queries in ~500ms.
* **Built-in PgBouncer:** Protects against connection exhaustion when multiple client instances or sync workers connect concurrently.

---

## 5. Free-Tier Limitations & Inactivity Policies (Honest Disclosures)

> [!WARNING]
> No commercial cloud vendor offers indefinite, guaranteed lifetime availability on free-tier infrastructure. DailySave is designed with operational resilience and portable standards (pure SQL, standard Docker containers, standard Git repositories) so it can migrate without vendor lock-in.

### Key Known Constraints:
1. **Render Free Web Service Sleep:**
   - Inactivity threshold: 15 minutes without an incoming HTTP request.
   - Impact: The first request after sleep experiences a 40–50 second delay while the container boots.
   - Workaround: A free external monitoring probe (e.g. UptimeRobot or BetterStack) polling `/health` every 10 minutes keeps the instance warm.
2. **Neon Compute Suspension:**
   - Inactivity threshold: 5 minutes.
   - Impact: First transaction query experiences a 500–800 ms latency spike.
3. **Storage Quota:**
   - 500 MB PostgreSQL capacity stores approximately 750,000 ledger transactions before requiring archiving or upgrading to a paid tier (\$5–\$19/month).
