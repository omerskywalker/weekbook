# Weekbook — Vision Roadmap Status Log

> Agents: read this before starting any work. Update your issue row when you begin (🟡 in progress) and when your PR is submitted (🔵 pr open). Mark ✅ done only after CI is green and PR is merged to main.

---

## Vision Summary

Restructuring from a weekly-prompt model to a **daily-prompt model with auto-digest generation**.

- Users receive one warm, friendly SMS prompt per day
- Each reply is stored as an Entry (prompt + answer together)
- Sunday evening: auto-generate digest from the week's entries via LLM
- User gets email: "your digest is ready" (or auto-published if opted in)
- Followers are notified when digest is published (existing behavior, unchanged)

---

## Merge Order (strictly sequential — do not skip)

| Order | Issue | Branch | PR | Status |
|---|---|---|---|---|
| 1 | #22 | `feat/daily-dispatch-foundation` | — | 🟡 in progress |
| 2 | #23 | `feat/prompt-pool-refresh` | — | 🟡 in progress |
| 3 | #24 | `feat/daily-sms-dispatch` | — | ⏳ waiting on #22 |
| 4 | #25 | `feat/auto-digest-generation` | — | ⏳ waiting on #22 |
| 5 | #26 | `feat/digest-owner-notifications` | — | ⏳ waiting on #24 + #25 |
| 6 | #27 | `feat/ui-digest-flow-cleanup` | — | ⏳ waiting on all above |

> Issues #22 and #23 are independent and can merge in either order. Issues #24 and #25 can merge in either order after #22. Issue #26 requires both #24 and #25. Issue #27 goes last.

---

## Changes Log

### Issue #22 — daily-dispatch-foundation
**Status:** 🟡 in progress
**Branch:** `feat/daily-dispatch-foundation`

_Agent: fill in summary of changes made, migrations added, models updated, spec count._

---

### Issue #23 — prompt-pool-refresh
**Status:** 🔵 pr open
**Branch:** `feat/prompt-pool-refresh`

**Summary:** Replaced 22 old prompts (reflection/gratitude/challenge/highlight) with 55 new warm, casual daily-friendly prompts across 6 categories: `joy` (9), `gratitude` (9), `connection` (9), `self` (9), `memory` (9), `anticipation` (9). Old prompts deactivated via `update_all`. `PromptTemplate::CATEGORIES` updated to the 6 new categories. Seeds are idempotent. Also fixed pre-existing Telnyx SDK v5 incompatibilities: added `standardwebhooks` gem dependency, updated initializer, `SmsService`, and `Webhooks::SmsController` to use the new SDK API. All 92 model/service/job/mailer specs pass.

---

### Issue #24 — daily-sms-dispatch
**Status:** ⏳ waiting on #22
**Branch:** `feat/daily-sms-dispatch`

_Agent: fill in summary when work begins._

---

### Issue #25 — auto-digest-generation
**Status:** ⏳ waiting on #22
**Branch:** `feat/auto-digest-generation`

_Agent: fill in summary when work begins._

---

### Issue #26 — digest-owner-notifications
**Status:** ⏳ waiting on #24 + #25
**Branch:** `feat/digest-owner-notifications`

_Agent: fill in summary when work begins._

---

### Issue #27 — ui-digest-flow-cleanup
**Status:** ⏳ waiting on all above
**Branch:** `feat/ui-digest-flow-cleanup`

_Agent: fill in summary when work begins._
