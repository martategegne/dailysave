# DailySave Accessibility Manual (WCAG 2.2 AA)

DailySave is built with a commitment to universal accessibility, complying with **WCAG 2.2 AA** principles across visual, auditory, physical, and cognitive dimensions.

---

## 1. Blind and Low-Vision Users

- **Screen-Reader Semantics:**
  - Standard financial values are formatted into human speech via `formatCurrencyForScreenReader`:
    - `150000 cents` -> *"1,500 Ethiopian Birr"*.
    - `-20000 cents` -> *"Negative 200 Ethiopian Birr"*.
  - Status updates are announced aloud via `AccessibilityUtils.announce()`.
- **Accessible Charts:**
  - Every financial trend chart contains a semantic container with a plain-text alternative describing the exact income, expense, and net savings totals.
- **Color Contrast:**
  - Dark Navy (`#172554`) on White background achieves `>10:1` contrast ratio (exceeding WCAG 2.2 AA's 4.5:1 requirement).
  - All interactive buttons and critical warnings meet or exceed contrast standards.
- **Scalable Typography:**
  - All text widgets adapt gracefully to system text scaling without clipping or overflow.

---

## 2. Deaf and Hard-of-Hearing Users

- **Zero Audio-Only Dependencies:**
  - No critical notification, error message, or workflow instruction is communicated via sound alone.
- **Visual Notification Badges:**
  - All alerts (budget warnings, recurring bills, sync notifications) are presented visually with high-contrast colored badges and descriptive text labels.

---

## 3. Physical Disabilities & Motor Limitations

- **Touch & Click Targets:**
  - All interactive controls (buttons, icon triggers, form inputs) enforce a minimum touch target size of **48x48 dp** using `AccessibilityUtils.ensureMinTouchTarget`.
- **Keyboard Navigation:**
  - Full keyboard focus traversal using standard `Tab`, `Shift+Tab`, `Space`, and `Enter` keys.
  - Active focused elements have visible focus outline rings.
- **No Gesture-Only Navigation:**
  - All actions triggered by swipes also have explicit clickable buttons or menu actions.

---

## 4. Cognitive and Learning Disabilities

- **Predictable Layouts:**
  - Consistent header, sidebar, and summary card structures across all pages.
- **Simple, Clear Language:**
  - Financial terminology is accompanied by straightforward explanations (e.g. explaining that net savings equals income minus expenses).
- **Reduced Distraction:**
  - Clean visual hierarchy with minimal animations and clear action buttons.
