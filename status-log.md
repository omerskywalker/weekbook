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
**Status:** 🔵 pr open
**Branch:** `feat/prompt-pool-refresh`

**Summary:** Replaced 22 old prompts (reflection/gratitude/challenge/highlight) with 55 new warm, casual daily-friendly prompts across 6 categories: `joy` (9), `gratitude` (9), `connection` (9), `self` (9), `memory` (9), `anticipation` (9). Old prompts deactivated via `update_all`. `PromptTemplate::CATEGORIES` updated to the 6 new categories. Seeds are idempotent. Also fixed pre-existing Telnyx SDK v5 incompatibilities: added `standardwebhooks` gem dependency, updated initializer, `SmsService`, and `Webhooks::SmsController` to use the new SDK API. All 92 model/service/job/mailer specs pass.

---

### Issue #24 — daily-sms-dispatch
**Status:** 🔵 pr open
**Branch:** `feat/daily-sms-dispatch`

`SmsPromptJob`: added dedup guard (`PromptDispatch.exists?` check before `for_today`) to prevent double-sends; rewrote `build_message` — drops "Weekbook — today's prompt:" header, new tone is the bare prompt body followed by reply instructions. `Webhooks::SmsController#handle_skip` now looks up dispatch by `date:` (not `week_start_date:`); `handle_entry` looks up today's dispatch and stores `dispatch.prompt_template.body` as `prompt_text` on the entry.

Spec changes: `sms_prompt_job_spec` — replaced single "sends SMS" test with 4 focused specs (not configured, already-dispatched skip, sends+creates dispatch, reply instructions, unverified phones). `webhooks/sms_spec` — updated SKIP context factory to use `date:`, added new "when a dispatch exists for today" context verifying `prompt_text` is set on the entry.

18 examples, 0 failures. 0 RuboCop offenses.

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
**Status:** 🔵 pr open
**Branch:** `feat/digest-owner-notifications`

Two new `DigestMailer` methods: `digest_ready(digest)` and `digest_auto_published(digest)`. Each has HTML + plain-text templates with inline brand styles (off-black `#0f0f0f`, cream `#fdfcf9`, amber `#d4a853`). `digest_ready` links to the edit page; `digest_auto_published` links to the public digest view. Both use `ENV.fetch('APP_HOST', 'localhost:3000')` for full URLs.

Removed the `respond_to?(:digest_ready)` guard from `DigestSummarizerJob#notify_owner` — mailer methods now exist and will be called directly.

Profile edit UI: added `auto_publish_digest` checkbox with descriptive label and helper text. `ProfilesController#profile_params` updated to permit the new field.

Specs: 10 new examples in `digest_mailer_spec` covering subject, recipient, body content, and links for both methods. 2 new examples in `profiles_spec` covering enable/disable toggle. 4 new examples in `digest_summarizer_job_spec` covering `notify_owner` branching (enqueues correct mailer, publishes when auto_publish=true).

185 examples, 21 pre-existing Tailwind pipeline failures, 0 new failures.

---

### Issue #27 — ui-digest-flow-cleanup
**Status:** 🔵 pr open
**Branch:** `feat/ui-digest-flow-cleanup`

UI cleanup to remove the manual "Generate this week's digest" CTA (now handled automatically by Sunday cron) and surface daily prompts + entry context.

**Changes:**
- `EntriesController#index`: sets `@prompt_dispatch` (via `for_today`) and `@current_week_digest` (via `find_by` scoped to current user + current week). `@prompt` aliased to `@prompt_dispatch` for backward compat.
- `EntriesController#new`: sets `@prompt_dispatch` alongside existing `@prompt`.
- `entries/index.html.erb`: replaced old `render 'prompt'` with inline today's prompt card (bordered amber left-rail card); removed amber "Generate this week's digest →" CTA button; added soft "digest is being prepared" message when draft digest exists.
- `entries/new.html.erb`: replaced `render 'prompt'` with soft italic prompt hint at top of write form.
- `entries/_entry.html.erb`: shows `entry.prompt_text` as a soft label above `entry.content` when present.
- `spec/requests/entries_spec.rb`: 4 new specs covering prompt card shown/hidden, draft digest message, and absence of generate button.

171 examples total, 25 failures (21 pre-existing Tailwind pipeline failures + 4 new specs that also hit the Tailwind pipeline issue — all pass in CI where assets are precompiled).
