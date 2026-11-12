# Domain Architecture, DNS Configuration & SSL Setup

This guide details the domain registration, multi-subdomain topology, DNS records, and SSL/TLS security configuration for DailySave in production.

---

## 1. Production Domain Architecture

DailySave decouples marketing discovery, authenticated financial application state, and backend processing across distinct subdomains:

| Subdomain | Role | Target Platform | Protocol & Port | Access Policy |
| :--- | :--- | :--- | :--- | :--- |
| **`dailysave.et`** | Apex / Root Domain | Cloudflare Page Rule / Redirect | HTTPS (443) | Permanent 301 Redirect to `https://www.dailysave.et` |
| **`www.dailysave.et`** | Public SEO Marketing Website | Cloudflare Pages (`dailysave-site`) | HTTPS (443) | Public, Search Indexed, Multilingual |
| **`app.dailysave.et`** | Flutter Web Application (PWA) | Cloudflare Pages (`dailysave-app`) | HTTPS (443) | Public assets, Authenticated Dashboard, `noindex` |
| **`api.dailysave.et`** | REST API & Sync Server | Render / Koyeb Web Service | HTTPS (443) | Strict CORS (`app.dailysave.et`), JWT Auth, Rate Limited |

---

## 2. Domain Selection & Registration

### Recommended Domain Names:
1. **`dailysave.et`** (Primary National Identity): Registered via Ethio Telecom or accredited registrars (e.g. `registry.et`). Provides strong regional branding in Ethiopia.
2. **`dailysave.app`** (Global FinTech Identity): Registered via Cloudflare Registrar or Porkbun with built-in HSTS preload requirement enforced by Google Registry.
3. **`dailysave.org`** (Community & Financial Literacy): Ideal for community-first positioning.

---

## 3. Authoritative DNS Zone Records (Cloudflare DNS)

The following DNS zone file reflects the complete production configuration in Cloudflare DNS:

```dns-zone
; ==============================================================================
; DailySave Production DNS Zone Configuration
; Domain: dailysave.et
; ==============================================================================

; --- Apex Domain & Web Redirects ---
@               IN  CNAME   www.dailysave.et.                 ; Proxied (Orange Cloud)

; --- Public SEO Marketing Website (Cloudflare Pages) ---
www             IN  CNAME   dailysave-website.pages.dev.      ; Proxied (Orange Cloud)

; --- Flutter Web Application Dashboard (Cloudflare Pages) ---
app             IN  CNAME   dailysave-app.pages.dev.          ; Proxied (Orange Cloud)

; --- Backend REST API Service (Render / Koyeb) ---
api             IN  CNAME   dailysave-api.onrender.com.       ; Proxied (Orange Cloud)

; --- Certificate Authority Authorization (CAA) Records ---
@               IN  CAA     0 issue "letsencrypt.org"
@               IN  CAA     0 issue "pki.goog"
@               IN  CAA     0 issuewild "letsencrypt.org"
@               IN  CAA     0 iodef "mailto:security@dailysave.et"

; --- Email Authentication & Anti-Phishing (SPF, DKIM, DMARC) ---
@               IN  TXT     "v=spf1 include:_spf.mx.cloudflare.net ~all"
_dmarc          IN  TXT     "v=DMARC1; p=reject; rua=mailto:dmarc-reports@dailysave.et; pct=100"
```

---

## 4. Cloudflare SSL/TLS & Edge Security Configuration

### A. Encryption Mode: Full (Strict)
* Cloudflare connects to the origin server using valid, authenticated SSL/TLS certificates only.
* Never use *Flexible* mode in financial applications, as communication between Cloudflare and the origin server would otherwise be transmitted over unencrypted HTTP.

### B. Minimum TLS Version & Cipher Suites
* **Minimum TLS Version:** `TLS 1.2`
* **TLS 1.3:** Enabled with 0-RTT connection resumption.
* **Opportunistic Encryption & Automatic HTTPS Rewrites:** Enabled.

### C. HTTP Strict Transport Security (HSTS)
Enforce HSTS headers across all hostnames:
* **Max-Age:** `31,536,000` seconds (1 Year)
* **Include Subdomains:** Enabled (`true`)
* **Preload:** Enabled (qualifies domain for global browser HSTS preload lists)

### D. Cloudflare Redirect Rules (Apex to WWW)
Create a single Redirect Rule in Cloudflare Dashboard:
* **Rule Name:** `Redirect Apex to WWW`
* **Matching Expression:** `(http.host eq "dailysave.et")`
* **Target URL:** `https://www.dailysave.et/$1`
* **Status Code:** `301 Moved Permanently`

---

## 5. Production Environment Variables Checklist

### Frontend (`app.dailysave.et`):
Injected at build time via Flutter `--dart-define`:
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://api.dailysave.et/api/v1
```

### Backend (`api.dailysave.et`):
Configured in cloud hosting provider dashboard (Render / Koyeb / Docker):
```env
NODE_ENV=production
PORT=4000
API_PREFIX=/api/v1
ALLOWED_ORIGINS=https://app.dailysave.et,https://www.dailysave.et
DB_HOST=ep-example.eu-central-1.aws.neon.tech
DB_PORT=5432
DB_NAME=dailysave_prod
DB_USER=dailysave_owner
DB_PASSWORD=<SECURE_PROD_PASSWORD>
DB_SSL=true
JWT_ACCESS_SECRET=<64_CHAR_RANDOM_HEX>
JWT_REFRESH_SECRET=<64_CHAR_RANDOM_HEX>
JWT_ACCESS_EXPIRES_IN=900
JWT_REFRESH_EXPIRES_IN=2592000
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```
