# Subscription System & Feature Entitlements Engine

DailySave implements a deterministic, multi-state subscription lifecycle engine that gates premium capabilities based on verified workspace entitlements.

---

## 1. Subscription Lifecycle States

```
                +-------------------+
                |     trialing      |
                +---------+---------+
                          |
                          v
+-------------+      +----+----+      +-------------+
|   expired   |<-----+ active  +----->|  past_due   |
+-------------+      +----+----+      +------+------+
                          |                  | (Grace Period: 7 Days)
                          v                  v
                     +----+----+      +------+------+
                     | canceled|      |   expired   |
                     +---------+      +-------------+
```

| Status | Definition | Entitlement Access Policy |
| :--- | :--- | :--- |
| **`active`** | Paid plan in good standing | Full plan entitlements enabled. |
| **`trialing`** | 14-day promotional free trial | Full plan entitlements enabled. |
| **`past_due`** | Payment failed or renewal pending | **7-Day Grace Period:** Retains plan entitlements for 7 days before downgrading. |
| **`canceled`** | User requested cancellation | Retains plan entitlements until `current_period_end`. |
| **`expired`** | Grace period elapsed / term finished | **Immediate Fallback:** Access reverts strictly to `FREE` plan entitlements. |

---

## 2. Feature Entitlement Evaluation

Entitlements are decoupled from UI checks and evaluated via the backend `isEntitled(subscription, entitlement)` engine:

```javascript
import { PLAN_CONFIG, PLANS } from './entitlements.js';

export function isEntitled(subscription, requiredEntitlement) {
  if (!subscription) return false;

  const isGoodStanding =
    subscription.status === 'active' ||
    subscription.status === 'trialing';

  const isGracePeriod =
    subscription.status === 'past_due' &&
    subscription.grace_period_end &&
    new Date(subscription.grace_period_end) > new Date();

  if (!isGoodStanding && !isGracePeriod) {
    // Fallback strictly to FREE tier entitlements
    return PLAN_CONFIG[PLANS.FREE].entitlements.includes(requiredEntitlement);
  }

  const planConfig = PLAN_CONFIG[subscription.plan] || PLAN_CONFIG[PLANS.FREE];
  return planConfig.entitlements.includes(requiredEntitlement);
}
```

---

## 3. Plan Upgrades & Downgrades

* **Upgrades:** Applied immediately upon invoice generation; resets `current_period_end` to +30 days (monthly) or +365 days (annual).
* **Downgrades:** Scheduled to take effect at the conclusion of the active billing period (`cancel_at_period_end = true`).
* **Cancellation:** Does not instantly lock out user data. Users retain access to their current tier until the period concludes, after which their workspace transitions gracefully to `FREE` without data deletion.
