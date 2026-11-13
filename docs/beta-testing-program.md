# DailySave Beta Testing Program & Quality Assurance Protocols

This manual establishes the three-stage testing architecture, tester cohort management, feedback triage, and quality criteria for releasing DailySave Version 1.0.

---

## 1. Three-Stage Release Architecture

```
+---------------------------------------------------------------------------------------+
|                                DailySave Release Stages                               |
+-------------------+-----------------------------------+-------------------------------+
|   STAGE 1: ALPHA  |          STAGE 2: CLOSED BETA     |     STAGE 3: PUBLIC BETA      |
|   Internal Only   |         Invited User Cohorts      |      Open Public Access       |
+-------------------+-----------------------------------+-------------------------------+
| Fictional Data    | University Students (AAU, Jimma)  | Public Web Registration       |
| Math Verification | Family Budget Managers            | Real Personal Transactions    |
| Chaos & Offline   | Small Business Retailers          | Feedback & CSAT Pipeline      |
| Crash Forensics   | Community Equb Circles            | Release Notes V1.0-RC         |
+-------------------+-----------------------------------+-------------------------------+
```

### Stage 1: Private Alpha (Completed)
* **Audience:** Core engineering team and trusted security peers.
* **Data Policy:** **Fictional financial records strictly.** No real personal financial data was permitted in test databases.
* **Focus:** Integer minor-unit arithmetic edge cases, network partition simulation, IndexedDB/SQLite offline durability, JWT refresh rotation attacks.

### Stage 2: Closed Beta (Current Stage)
* **Audience:** 150 invited participants across 5 discrete cohorts:
  1. *University Students:* Tracking stipends and campus expenses on mobile Web.
  2. *Individual Salary Earners:* Daily expense tracking and personal savings goals.
  3. *Households & Families:* Shared grocery budgets and joint savings pools.
  4. *Small Businesses & Kiosks:* Daily cash register, staff permissions, customer credit.
  5. *Community Equb Circles:* Organizing contribution cycles and payout schedules.
* **Feedback Mechanism:** In-app bug reporter and `/api/v1/feedback`.

### Stage 3: Public Beta (Version 1.0 Release Candidate)
* **Audience:** General public access via `https://www.dailysave.et` and `https://app.dailysave.et`.
* **Disclosures:** Clear beta status labels, explicit privacy consent, non-custodial software disclaimer.

---

## 2. Beta Feedback & Defect Triage Severity Levels

Every submission through `website/feedback.html` or `POST /api/v1/feedback` is classified by severity:

| Severity | Definition | Resolution SLA | Example Defect |
| :--- | :--- | :--- | :--- |
| **P0 — Critical** | Mathematical error, financial data corruption, security vulnerability, data leakage | `< 4 Hours` (Immediate hotfix) | Balance discrepancy between transactions and net savings summary. |
| **P1 — High** | Offline sync failure, screen-reader blocking bug, authentication crash | `< 24 Hours` | TalkBack unable to focus on transaction save button; sync deadlock. |
| **P2 — Medium** | Layout glitch, translation omission in Amharic/Oromo, non-blocking UI issue | `< 72 Hours` | Ge'ez numeral alignment slightly truncated on small 320px screens. |
| **P3 — Low** | Feature suggestion, minor cosmetic preference | Scheduled roadmap | Request for custom category icon colors. |

---

## 3. User Satisfaction (CSAT) Survey Questions

Administered after 14 days of active usage:
1. *On a scale of 1 to 5, how clear and trustworthy are the financial calculations in DailySave?*
2. *Did you experience any data loss or sync discrepancies when using the app offline?*
3. *How easy was it to navigate DailySave using your preferred language (English, Amharic, Afaan Oromo) or screen reader?*
4. *What was the single most useful feature for your household, business, or Equb?*
5. *What is one feature that could be improved before the official Version 1.0 release?*
