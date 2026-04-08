---
type: gotchas
tags: [gotchas, lessons-learned, weekbook]
last-updated: 2026-04-05
---

# Gotchas — Weekbook

> Read this before starting any task. Each entry is a real thing that burned us.
> Add new entries at the top with the date.

---

## 2026-04-05 — OmniAuth CSRF: `nil` does NOT disable validation

**Symptom:** OAuth sign-in silently breaks after setting `OmniAuth.config.request_validation_phase = nil`.

**Cause:** OmniAuth 2.1.x has a nil-guard in the source — setting to `nil` doesn't disable the middleware, it keeps the default behavior.

**Fix:** Use a no-op lambda: `OmniAuth.config.request_validation_phase = ->(env) {}`
Also required: `OmniAuth.config.allowed_request_methods = %i[post]` and `silence_get_warning = true`.
OAuth buttons must use `data: { turbo: false }` — Turbo intercepts `button_to` POSTs as `fetch()`, breaking the OAuth redirect.

---

## 2026-04-05 — Tailwind v4: no `tailwind.config.js`, stylesheet named `tailwind`

**Symptom:** `stylesheet_link_tag "application"` loads nothing; custom tokens don't apply.

**Cause:** This project uses Tailwind v4 CSS-first config. There is no `tailwind.config.js`. All design tokens live in `app/assets/tailwind/application.css` under `@theme`. The compiled output is named `tailwind`, not `application`.

**Fix:** Always use `stylesheet_link_tag "tailwind"` in layouts. Never create `tailwind.config.js` — add tokens to the `@theme` block in the CSS file.

---

## 2026-04-05 — `aws-sdk-s3` must be in the main gem group

**Symptom:** ActiveStorage works in development but crashes in production with a missing constant.

**Cause:** Production doesn't install dev/test gems. `aws-sdk-s3` was mistakenly in a dev group.

**Fix:** Keep `aws-sdk-s3` in the main (ungrouped) gem block in `Gemfile`.

---

## 2026-04-05 — DigestMailer needs `layout false`

**Symptom:** Email templates render with double `<html>` tags and broken styling.

**Cause:** Rails mailers inherit the application layout by default. The `DigestMailer` email templates provide their own complete HTML document with inline styles.

**Fix:** Add `layout false` to `DigestMailer`. Each template provides its own full HTML.

---

## 2026-04-07 — Twilio requires 10DLC brand registration even for personal/low-volume use

**Symptom:** Cannot send any US SMS via Twilio without completing A2P 10DLC brand registration, which requires a business EIN and takes days to approve.

**Cause:** Twilio now mandates 10DLC registration for all US A2P (application-to-person) traffic, with no exception for personal projects or low volume.

**Fix:** Migrated to Telnyx. Telnyx does not require brand registration for low-volume personal use. API is similar to Twilio but uses JSON webhooks (not TwiML) and a single API key (not SID+token pair). Inbound SMS is free; outbound is ~$0.004/msg.

---

## 2026-04-05 — `NotifyFollowersJob` spec: use `have_enqueued_mail`, not `ActionMailer::Base.deliveries`

**Symptom:** Spec for `NotifyFollowersJob` passes locally but fails in CI; `ActionMailer::Base.deliveries` is always empty.

**Cause:** `ActionMailer::Base.deliveries` only captures mail when the queue adapter is `:inline`. With the `:test` adapter (used in CI), jobs are enqueued but not immediately executed, so `deliveries` stays empty.

**Fix:** Use `expect { job.perform_now }.to have_enqueued_mail(DigestMailer, :new_digest)` — this works correctly with the `:test` adapter.

---

## 2026-04-05 — `RAILS_ENV` must be lowercase `production`

**Symptom:** App boots in development mode on Render despite env var being set.

**Cause:** Rails checks for the exact string `"production"`. If `RAILS_ENV=PRODUCTION` (uppercase), Rails falls back to development mode.

**Fix:** Always set `RAILS_ENV=production` (all lowercase) in Render environment variables.

---

## 2026-04-05 — `ActiveRecord::RecordNotFound` in request specs returns 404, not raises

**Symptom:** `expect { get ... }.to raise_error(ActiveRecord::RecordNotFound)` fails in request specs.

**Cause:** In request specs (integration layer), Rails catches `ActiveRecord::RecordNotFound` and renders a 404 response. It does not propagate as a Ruby exception to the test.

**Fix:** Assert `expect(response).to have_http_status(:not_found)` instead of `raise_error`.

---

## 2026-04-05 — Duplicate `queue_adapter = :test` causes Sidekiq conflicts

**Symptom:** CI spec failures related to job queue adapter being wrong.

**Cause:** Cherry-pick artifact left a duplicate `config.active_job.queue_adapter = :test` line in `config/environments/test.rb`.

**Fix:** Keep only one `queue_adapter = :test` declaration. Rails uses last-one-wins but duplicate lines can cause confusion and should be cleaned up.
