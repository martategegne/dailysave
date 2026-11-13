# Google Search Console, SEO Auditing & Privacy Analytics

This operational manual details the verification, indexing management, mobile usability checks, and privacy-conscious analytics setup for DailySave.

---

## 1. Google Search Console Configuration

Google Search Console (GSC) is the primary tool for indexing public marketing pages, diagnosing crawl errors, and monitoring organic search traffic.

### A. Domain Property Verification (Recommended)
Domain-level verification covers all protocols (`http://`, `https://`) and all subdomains (`www`, `app`, `api`).

1. Open [Google Search Console](https://search.google.com/search-console).
2. Select **Domain** property and enter `dailysave.et`.
3. Copy the provided `google-site-verification` TXT token.
4. Add the TXT record to Cloudflare DNS:
   ```dns-zone
   dailysave.et.   IN   TXT   "google-site-verification=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
   ```
5. Click **Verify** in Search Console.

### B. URL Prefix Verification (Alternative for Cloudflare Pages)
If DNS access is restricted, place an HTML meta tag inside `website/index.html`:
```html
<meta name="google-site-verification" content="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" />
```

---

## 2. Sitemap Submission & Indexing Monitoring

### A. Sitemap Submission
1. In Search Console, navigate to **Sitemaps** in the left sidebar.
2. Enter the sitemap URL: `https://www.dailysave.et/sitemap.xml`.
3. Click **Submit**.
4. Confirm status shows **Success** with 14 discovered URLs.

### B. Search Indexing Privacy Guardrails (Strict Rule)
> [!IMPORTANT]
> The authenticated application dashboard on `https://app.dailysave.et` houses private financial workflows.
> It MUST NEVER be submitted to Search Console or indexed by web search engines.
> 
> * Enforced via `web/robots.txt`:
>   ```
>   User-agent: *
>   Disallow: /
>   ```
> * Enforced via `web/index.html`:
>   ```html
>   <meta name="robots" content="noindex, nofollow">
>   ```

---

## 3. Mobile Usability & Core Web Vitals Targets

All 14 pages of the public website are optimized for mobile network conditions in East Africa:

| Metric | Target | DailySave Implementation |
| :--- | :--- | :--- |
| **LCP (Largest Contentful Paint)** | `< 2.5s` | Zero external font dependencies, native CSS variables, lightweight HTML. |
| **INP (Interaction to Next Paint)** | `< 200ms` | Zero heavy client frameworks; minimal vanilla JS (`site.js` < 2 KB). |
| **CLS (Cumulative Layout Shift)** | `< 0.1` | Static element dimensions, explicit aspect ratios. |
| **Touch Target Size** | `≥ 48x48 dp` | WCAG 2.2 AA compliant button and link hit areas. |

---

## 4. Privacy-Conscious Web Analytics Strategy

Many commercial analytics tools (such as default Google Analytics 4) drop persistent tracking cookies, gather IP addresses, and trigger mandatory cookie consent banners under GDPR and international privacy regulations.

### Comparative Analytics Options:

| Analytics Solution | Cookies Used | PII / IP Stored | Banner Required? | Cost | Recommendation |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Cloudflare Web Analytics** | **None** | None (Privacy-first beacon) | **No** | **Free** | **Primary Recommendation** |
| **Plausible Analytics** | None | Anonymized hash | No | \$9/mo | Secondary alternative |
| **Google Analytics 4 (GA4)** | Yes (`_ga`, `_gid`) | Truncated IP | Yes (Explicit consent banner required) | Free | Not recommended without consent banner |

### Implementation: Cloudflare Web Analytics (Cookieless)
Enable directly in the Cloudflare Dashboard under **Pages > Web Analytics**:
* Measures page views, visitor country, device type, and Core Web Vitals.
* Zero cookie banner required.
* 100% compliant with DailySave's zero-surveillance privacy model.
