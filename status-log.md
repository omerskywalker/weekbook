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
| 1 | #22 | `feat/daily-dispatch-foundation` | #29 | ✅ done |
| 2 | #23 | `feat/prompt-pool-refresh` | — | 🟡 in progress |
| 3 | #24 | `feat/daily-sms-dispatch` | — | 🔵 pr open |
| 4 | #25 | `feat/auto-digest-generation` | — | 🔵 pr open |
| 5 | #26 | `feat/digest-owner-notifications` | — | ⏳ waiting on #24 + #25 |
| 6 | #27 | `feat/ui-digest-flow-cleanup` | — | ⏳ waiting on all above |

> Issues #22 and #23 are independent and can merge in either order. Issues #24 and #25 can merge in either order after #22. Issue #26 requires both #24 and #25. Issue #27 goes last.

---

## Changes Log

### Issue #22 — daily-dispatch-foundation
**Status:** ✅ done
**Branch:** `feat/daily-dispatch-foundation`

3 migrations: `add_date_to_prompt_dispatches` (adds `date` column, replaces unique index on `[user_id, week_start_date]` with `[user_id, date]`, backfills existing rows), `add_prompt_text_to_entries` (nullable `prompt_text` string), `add_auto_publish_digest_to_users` (boolean default false).

Model changes: `PromptDispatch` adds `for_today(user)` class method, `for_current_week` now returns a relation, uniqueness validated on `:date`. `EntriesController` and `SmsPromptJob` updated to use `for_today`. Also fixed Telnyx 5.x compatibility: `SmsService` uses `Telnyx::Client`, webhook controller uses `StandardWebhooks::Webhook`. Added `standardwebhooks` gem.

159 examples, 21 pre-existing Tailwind pipeline failures (not introduced by this PR).

---

### Issue #23 — prompt-pool-refresh
**Status:** 🟡 in progress
**Branch:** `feat/prompt-pool-refresh`

_Agent: fill in summary of prompts added, categories used, seed count._

---

### Issue #24 — daily-sms-dispatch
**Status:** 🔵 pr open
**Branch:** `feat/daily-sms-dispatch`

_Agent: fill in summary when work begins._

---

### Issue #25 — auto-digest-generation
**Status:** 🔵 pr open
**Branch:** `feat/auto-digest-generation`

New `WeeklyDigestAutoGenerateJob` — iterates all users, finds those with entries this week, find-or-creates a draft digest, enqueues `DigestSummarizerJob` for each. Skips published and archived digests.

Updated `DigestSummarizerJob` signature from `(user_id, week_start_date_str)` to `(user_id, digest_id)`. After saving narrative, calls `notify_owner` which auto-publishes + emails if `user.auto_publish_digest` is true, otherwise emails a "digest ready" notification. Both mailer methods guarded with `respond_to?` so they're no-ops until Issue #26 adds them.

Updated `OpenaiSummarizer#build_entries_text` to emit `Q: <prompt>\nA: <content>` format when `entry.prompt_text` is present, giving GPT-4o richer context.

Added `archived?` predicate to `WeeklyDigest`. Added `:archived` factory trait.

Cron job to add on Render after merge: `bundle exec rails runner "WeeklyDigestAutoGenerateJob.perform_later"` on schedule `0 20 * * 0` (Sunday 8pm UTC).

171 examples, 21 pre-existing Tailwind pipeline failures, 0 new failures.

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
