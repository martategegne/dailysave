# Payment Gateway Integration & Regional Provider Evaluation

This document presents a technical and regulatory evaluation of payment processors for DailySave, focusing on Ethiopia and East African mobile money ecosystems.

---

## 1. Compliance Principles & Zero-Credential Storage

> [!CAUTION]
> **PCI-DSS & Security Mandate:**
> DailySave NEVER collects, processes, transmits, or stores credit/debit card numbers (PANs), expiration dates, CVVs, or mobile money PINs on its servers.
> All payment interactions utilize external hosted checkout pages, mobile wallet intent redirects, or tokenized webhooks.

### Current Implementation Status: Simulated Evaluation Mode
In accordance with production safety requirements:
* Live automated charges are **disabled**.
* The subscription system currently runs in a deterministic **Evaluation Mode** where invoices and plan changes are generated without debiting real customer funds.
* A live payment integration will only be connected after formal institutional review and testing of selected payment gateways.

---

## 2. Comprehensive Ethiopian Payment Provider Matrix

| Provider | Supported Payment Rails | Settlement Currency & Time | Estimated Transaction Fees | API & Developer Experience | Compliance & Eligibility Requirements | Verdict for DailySave |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Chapa Financial Technologies** | Telebirr, CBE Birr, Awash Birr, Visa, Mastercard | **ETB**, Settles T+1 to Ethiopian bank accounts | ~2.5% – 3.5% | **High:** Modern REST API, hosted modal, sandbox keys, HMAC-SHA256 webhooks | Requires Ethiopian TIN, Commercial Business License, bank certificate | **Top Recommendation for Gateway Integration** |
| **Telebirr (Ethio Telecom)** | Direct Telebirr mobile wallet (60M+ users) | **ETB**, Settled to designated merchant account (T+2) | ~1.5% – 2.0% | **Medium:** H5 redirect, SuperApp mini-program SDK, RSA-SHA256 signature signing | Requires Ethio Telecom enterprise merchant agreement, corporate registration | **Essential for Market Penetration** |
| **CBE Birr (Commercial Bank of Ethiopia)** | CBE Birr mobile wallet & accounts | **ETB**, Direct CBE deposit (T+0 to T+1) | ~1.0% – 2.0% | **Moderate:** SOAP/REST banking gateway, fixed IP whitelisting | Institutional account with CBE, NBE regulatory compliance | Secondary direct integration |
| **ArifPay** | Mobile wallets, QR codes, debit cards | **ETB**, Settles to local bank accounts (T+1) | ~2.0% – 3.0% | **Good:** Android SDK, REST checkout API | Licensed PSO by National Bank of Ethiopia | Viable alternative gateway |

---

## 3. Recommended Integration Architecture: Chapa Gateway

Chapa provides a single unified API abstracting multiple Ethiopian payment rails (Telebirr, CBE Birr, Awash Birr, and international cards):

```
[ DailySave Client ] ──(1. Select Plan)──► [ DailySave Backend ]
                                                   │
                                                   │ 2. POST /v1/transaction/initialize
                                                   ▼
                                            [ Chapa Gateway ]
                                                   │
                                                   │ 3. Returns checkout_url
                                                   ▼
[ DailySave Client ] ◄──(4. Redirect)────── [ Hosted Checkout ]
        │                                          │
        │ 5. Complete Telebirr / CBE payment       │
        v                                          │ 6. Webhook (HMAC-SHA256)
[ Chapa Hosted Page ] ─────────────────────────────┼─────────────────────────┐
                                                                             ▼
                                                                  [ DailySave Backend ]
                                                                  (Verifies signature,
                                                                   marks subscription active,
                                                                   generates invoice)
```

### Webhook Verification Flow:
1. Chapa sends `POST /api/v1/subscriptions/webhooks/chapa` with `x-chapa-signature`.
2. DailySave backend computes HMAC-SHA256 hash using `CHAPA_WEBHOOK_SECRET` over raw request payload.
3. If signatures match, updates `subscriptions.status = 'active'` and marks `billing_invoices.status = 'paid'`.

---

## 4. Known Regional Regulatory & Inactivity Considerations

1. **National Bank of Ethiopia (NBE) Directives:** All domestic subscription transactions must settle in Ethiopian Birr (ETB). Pricing in foreign currencies for domestic services is regulated.
2. **Offline Payment Grace Periods:** Because network connectivity in remote areas is intermittent, DailySave includes an automatic **7-day grace period** on `past_due` subscriptions before revoking premium feature entitlements.
