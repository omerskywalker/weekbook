# Weekbook — Agent Context Pack

> Hand this file to any agent working on this codebase. It is the single source of truth for what has been built, what decisions were made, and what comes next.
> Last updated: 2026-03-28

## Wiki (read before starting any task)
- **Project wiki:** `WIKI/index.md`
- **Gotchas:** `WIKI/gotchas.md`
- **Agent guide:** `WIKI/agents.md`
- **Global wiki:** `~/.claude/wiki/index.md`

---

## Last Session — What Was Done

> **Updated after every coding session. Read this first to understand current state.**

**2026-04-07 — Twilio → Telnyx SMS migration**

Swapped the SMS provider from Twilio to Telnyx. Twilio now requires 10DLC brand registration for all US A2P traffic even for personal/low-volume use, which blocked setup. Telnyx does not require this for low-volume personal use.

**What changed:**
- `gem 'twilio-ruby'` → `gem 'telnyx'` in Gemfile
- `app/services/twilio_service.rb` → `app/services/sms_service.rb` (provider-agnostic name; uses `Telnyx::Message.create`)
- `app/controllers/twilio_webhooks_controller.rb` → `app/controllers/webhooks/sms_controller.rb` (namespaced; parses Telnyx JSON webhook instead of TwiML params; returns `head :ok` not TwiML XML)
- Route: `POST /webhooks/twilio` → `POST /webhooks/sms`
- `config/initializers/telnyx.rb` — sets `Telnyx.api_key` from env
- All `TwilioService` references updated to `SmsService` throughout jobs, models, specs
- Signature verification: `TELNYX_PUBLIC_KEY` env var (optional, skip verifies when absent — same pattern as before)
- `.env.example` updated: `TELNYX_API_KEY`, `TELNYX_PHONE_NUMBER`, `TELNYX_PUBLIC_KEY`
- All Twilio-specific specs replaced with Telnyx equivalents

**Key difference — webhook format:** Telnyx sends JSON (not form params). `from` is at `data.payload.from.phone_number`, message body at `data.payload.text`. Response is plain `200 OK`, not TwiML XML.

**Remaining action items:**
- Sign up at telnyx.com → free credits on signup
- Buy a number (~$1/mo) from their portal
- Set Telnyx number's inbound webhook URL: `https://weekbook.onrender.com/webhooks/sms`
- Set `TELNYX_API_KEY`, `TELNYX_PHONE_NUMBER` on Render (and optionally `TELNYX_PUBLIC_KEY` from Telnyx portal → API Keys → Public Key)
- `bundle install` to pull in the `telnyx` gem

---

**2026-03-28 — Rails 7.2 Upgrade + Email Notifications + SMS + CI Fix (PRs #17–#20)**

All four PRs merged. Here's what changed:

**PR #17 — Rails 7.1 → 7.2 upgrade**
Bumped the Rails constraint to `~> 7.2`. Resolves CVE-2026-33658 (activestorage DoS). `bundle-audit` now passes cleanly with no ignores needed.

**PR #18 — Follower email notifications**
When a digest is published, `NotifyFollowersJob` fans out `DigestMailer#new_digest` to every follower via `deliver_later`. Branded HTML + plain-text email with inline styles. Fixed `DigestMailer` with `layout false` — template provides its own complete HTML doc. SMTP reads from env vars in production. **To activate: add `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `APP_HOST` to Render.** Recommended: Postmark (free 100/month) — use API token as both username and password.

**PR #19 — Phase 7 SMS ingestion**
Full Twilio integration. `TwilioService` thin wrapper (no-op when env vars absent). `PhoneUtils.normalize` E.164 normalization (+1 prepend for 10-digit US). `TwilioWebhooksController` — `POST /webhooks/twilio` maps inbound SMS to Entry, `SKIP` body skips week's prompt. `PhoneVerificationsController` — OTP flow at `/phone_verification`. `SmsPromptJob` (Sidekiq `low` queue) sends weekly prompt SMS to verified users. Profile edit shows phone status. **Activate: verify `TWILIO_ACCOUNT_SID` starts with `AC` (not `MG`), rotate auth token (was shared in chat).**

**PR #20 — CI spec fix**
Two cleanup items: (1) removed duplicate `queue_adapter = :test` line in `test.rb` (cherry-pick artifact), (2) fixed `NotifyFollowersJob` spec from `ActionMailer::Base.deliveries` (only works with `:inline`) to `have_enqueued_mail` (works with `:test` adapter).

**Remaining action items:**
- **Postmark SMTP**: postmarkapp.com → create server → copy API token → set `SMTP_HOST=smtp.postmarkapp.com`, `SMTP_PORT=587`, `SMTP_USERNAME=<token>`, `SMTP_PASSWORD=<token>`, `APP_HOST=weekbook.onrender.com`
- **SMS cron**: Render Cron Job → `bundle exec rails runner "SmsPromptJob.perform_later"` → `0 14 * * 1`
- **Branch protection**: GitHub → Settings → Branches → require `lint`, `security`, `test` on main
---

**2026-03-27 — CI Pipeline + Pre-push Hooks (PR #16, branch `feat/ci`)**

Set up the full quality gate so bad code can't sneak in undetected.

**GitHub Actions** (`.github/workflows/ci.yml`) runs three parallel jobs on every push and PR: **lint** (RuboCop `--parallel`), **security** (Brakeman static analysis + `bundle-audit` CVE advisory check), and **test** (full RSpec suite against a PostgreSQL 16 service container). Jobs are independent so they run simultaneously — a lint failure doesn't block the test result.

**Local pre-push hook** (`.githooks/pre-push`) runs RuboCop + RSpec before your push even leaves your machine. That way CI isn't your first line of defense — you find out immediately in the terminal. Bypass it when needed with `SKIP_HOOKS=1 git push`. The hook lives in `.githooks/` which is tracked in git, so everyone who clones the repo gets it. One-time activation: `bin/setup-hooks` (already run on this machine).

**`brakeman`** and **`bundler-audit`** added to the dev Gemfile. Brakeman does static security analysis (SQL injection, XSS, etc.) — found zero real issues. EOLRuby and EOLRails warnings are skipped in CI since those are upgrade tasks, not vulnerabilities. Note: **Ruby 3.2 EOL is 2026-03-31** and Rails 7.1 is already past EOL — these should be upgraded soon.

Fixed all 59 autocorrectable RuboCop offenses found across the existing codebase as part of this PR.

**One thing to do after merging:** In GitHub → repo Settings → Branches → main → Branch protection rules → add required status checks: `lint`, `security`, `test`. This blocks merging PRs that fail CI.

---

**2026-03-27 — Phase 6 + Phase 8: AI Summarization, Pundit Auth, Error Pages, OG Meta (PRs #14 + #15)**

Two PRs built in parallel:

**PR #15 — feat/ai-summarization (Phase 6 — merge first)**

The "generate your weekly digest" feature. Wired Sidekiq as the ActiveJob backend (`config/application.rb`) with a Redis initializer that reads `REDIS_URL`. Built two new pieces: `OpenaiSummarizer` service (calls GPT-4o with a reflective system prompt — "warm first-person narrative, no bullet points, sound human"), and `DigestSummarizerJob` (Sidekiq job that loads entries + prompt, calls the service, saves to WeeklyDigest). Service gracefully no-ops if `OPENAI_API_KEY` is absent. UI: amber "Generate this week's digest →" card on entries index (only when entries exist). New `POST /weekly_digests/:id/generate` route + action — enqueues job, redirects to edit with a "refresh in 15s" notice.

**Before this works in production, you need to:**
1. Create a Render Redis instance → set `REDIS_URL` env var
2. Add a Render worker service: start command `bundle exec sidekiq`
3. Add `OPENAI_API_KEY` env var

**PR #14 — feat/polish (Phase 8 — merge second)**

Four improvements: (1) **Pundit** — `WeeklyDigestPolicy` and `EntryPolicy` now enforce ownership at the controller layer, not just in views. Drafts actually 403 for non-owners. (2) **Branded error pages** — replaced `public/404.html` and `public/500.html` with Weekbook-styled HTML (off-black, cream, amber dot, proper fonts). (3) **OG meta tags** — digest show page emits `og:title`, `og:description` so link previews work. (4) **N+1 fix** — feed controller eager-loads `user: { avatar_attachment: :blob }`. 46 policy specs, all passing.

**Merge order: PR #15 (AI) first, then PR #14 (polish).** PR #14 references `generate?` in the Pundit policy which expects the generate action to exist.

---

**2026-03-27 — Mobile Responsiveness (PR #13, branch `feat/mobile`)**

The app looked good on desktop but broke on mobile. Here's what we fixed:

**Nav (the main piece):** Built a Stimulus controller (`mobile_menu_controller.js`) that drives a hamburger menu. The desktop nav links are now wrapped in `hidden md:flex` so they only appear at medium+ breakpoints. Below `md`, a hamburger icon appears instead. Tapping it toggles a slide-down dropdown, and the icon swaps between open/close states. Every link in the dropdown has a `click->mobile-menu#close` action so the menu collapses when you navigate.

**Card padding:** Most cards had a flat `p-6` or `p-8` — tight on a 375px screen. Changed these to `p-4 sm:p-6` and `p-4 sm:p-8` across digest show/new/edit, profile edit, and the digest form wrapper. Small change, big difference in feel.

**Auth pages:** The sign in/sign up cards were centered but had no horizontal buffer — they could press right up to the screen edge on small viewports. Added `px-4` to the outer wrapper so there's always a margin.

**Header rows:** The digest index page and feed page both had a header with the title on the left and a CTA button on the right (`flex justify-between`). On narrow screens this would overflow. Added `flex-wrap gap-y-3` so the button drops to a new line cleanly instead.

**Entry write:** The full-screen write view had `pt-16` top padding — too much on mobile, cuts into usable space. Changed to `pt-8 sm:pt-16`.

**Also included in this commit:** `CLAUDE.md` (this file) — added as a tracked file so it travels with the repo and is auto-loaded by Claude Code every session.

**Pending actions for you:**
- Merge PR #13 (`feat/mobile`) after merging PRs 10, 11, 12 in order (entries → prompts → feed → mobile)
- After merging feat/prompts (PR #11), run `bundle exec rails db:seed` on Render to load the 22 prompt templates

---

## Product Vision

Weekbook is a **behavioral journaling product**, not a social media app.

**Core thesis:** Small, low-effort inputs (journal entries, SMS replies to prompts) → meaningful weekly narrative (WeeklyDigest). The digest is the only public artifact — a synthesized weekly story, not a traditional post.

**Core loop:**
1. User receives a weekly prompt (or writes freely)
2. Logs raw entries throughout the week (web UI or SMS)
3. Entries are **always private**
4. At week's end: one click generates an AI narrative from the entries
5. User edits and optionally publishes the digest
6. Followers see published digests in their feed

**Why it's different:**
- Existing social platforms reward performance, not reflection
- Entries ≠ posts — the separation is the entire point
- SMS ingestion removes the app entirely from the capture loop
- AI summarization reduces effort to near zero
- Weekly digest format is calmer and more honest than daily posting

---

## Stack

| Layer | Technology |
|---|---|
| Framework | Rails 7.1.6 |
| Database | PostgreSQL (Render managed) |
| Frontend | Tailwind CSS v4 (CSS-first `@theme`), Hotwire (Turbo + Stimulus) |
| Auth | Devise + OmniAuth (Google, GitHub) |
| File uploads | ActiveStorage + AWS S3 |
| Background jobs | Sidekiq (not yet wired — needed for Phase 6) |
| AI | ruby-openai (Phase 6) |
| SMS | twilio-ruby (Phase 7) |
| Testing | RSpec + FactoryBot |
| Deployment | Render (Ruby native environment, not Docker) |

---

## Design System

**Do not deviate from this palette or font pairing.**

### Colors (defined in `app/assets/tailwind/application.css` via `@theme`)
- `cream-50/100/200/300/400` — warm off-white surfaces (`#fdfcf9` → `#d9cbb4`)
- `ink-900` — near-black `#0f0f0f` (nav background)
- `ink-800/700/600/500/400/300` — text hierarchy
- `amber` — `#d4a853` — the single accent color (CTAs, week numbers, highlights)
- `amber-light` — `#e8c97a` — hover state for amber
- `amber-dark` — `#b8892e` — active/dark amber
- `shadow-warm` — subtle warm shadow used on all cards

### Typography
- **Body:** `Inter` (Google Fonts, loaded in layout)
- **Display/headings:** `Fraunces` (Google Fonts, variable font — use `font-display` Tailwind class)
- Week numbers always in `font-display text-amber`

### Motion
- `animate-slide-up` — page entry animation
- `animate-fade-in` — used by `fade_in_controller.js` (IntersectionObserver)
- Hover micro-lifts: `hover:-translate-y-px active:translate-y-0`
- All transitions: `transition-all duration-150` or `duration-200`

### UI Principles
- **One action per screen**
- **Week as the primary unit** — always show week number as visual anchor
- **Empty states are designed** — never leave default blank states
- **Background:** `bg-cream-200` body, `bg-white` cards with `shadow-warm`
- **Nav:** `bg-ink-900` sticky, amber dot logo mark

---

## Repository Structure

```
app/
  assets/tailwind/application.css   # Entire design system lives here (@theme)
  controllers/
    entries_controller.rb           # CRUD for private entries
    feed_controller.rb              # Feed of published digests from followed users
    feed_controller.rb
    follows_controller.rb
    home_controller.rb
    profiles_controller.rb
    prompt_dispatches_controller.rb # Skip action for weekly prompts
    users/omniauth_callbacks_controller.rb
    weekly_digests_controller.rb    # Draft/publish workflow
  javascript/controllers/
    char_count_controller.js        # Live counter + Cmd+Enter submit
    fade_in_controller.js           # IntersectionObserver fade-in
  models/
    user.rb
    entry.rb                        # Private raw input (5-500 chars)
    weekly_digest.rb                # The public artifact
    prompt_template.rb              # Prompt bank (22 seeded)
    prompt_dispatch.rb              # One per user per week
    follow.rb
    identity.rb                     # OAuth identity (provider + uid)
  views/
    layouts/application.html.erb   # Nav, flash messages, Google Fonts
    entries/                        # index (quick-add + list), new (full-screen)
    feed/                           # index, _digest_card, _suggestion
    weekly_digests/                 # index, show, new, edit, _form
    devise/sessions/new.html.erb    # Sign in with OAuth buttons
    devise/registrations/new.html.erb
db/
  migrate/                          # 9 migrations (see below)
  seeds.rb                          # 22 prompt templates, idempotent
spec/
  factories/                        # users, entries, weekly_digests, prompt_templates, prompt_dispatches
  models/                           # entry, weekly_digest, prompt_template, prompt_dispatch specs
  requests/                         # entries, feed, weekly_digests, (+ devise helpers)
```

---

## Data Model

### Users
- Devise auth: email + password + OAuth (Google, GitHub)
- Profile fields: `username`, `display_name`, `bio`
- Avatar via ActiveStorage → S3
- `has_many :entries, :weekly_digests, :prompt_dispatches, :identities`
- Social graph via `follows` join table (`follower_id`, `followed_id`)

### Entry
- Always **private** — never publicly accessible
- `user_id`, `content` (5–500 chars), `week_start_date` (auto-set to Monday on create), `prompt_ref`
- Scopes: `for_week(date)`, `recent`

### WeeklyDigest
- The only public artifact
- `user_id`, `week_start_date` (always a Monday), `week_number`, `year`, `content`, `summary_line` (max 160), `status` (draft/published/archived)
- Unique index on `[user_id, week_start_date]`
- `published?`, `draft?`, `publish!`, `unpublish!`
- `for_week(date)` class method — finds or initializes by Monday

### PromptTemplate
- Seed data: 22 prompts across 4 categories: `reflection`, `gratitude`, `challenge`, `highlight`
- `active` boolean, `random_for_week` picks a random active one

### PromptDispatch
- One per user per week (unique index on `[user_id, week_start_date]`)
- Created on first visit to `/entries` or `/entries/new` each week
- Statuses: `pending`, `responded`, `skipped`
- Shown as dismissible banner above entry form

### Identity
- Links OAuth provider+uid to a User
- Used by `User.from_omniauth(auth)` — creates Identity + User if new, returns existing user if returning

### Follow
- `follower_id` → `followed_id`
- `User#following?`, `User#following`, `User#followers`

---

## Routes

```ruby
root 'home#index'
get '/feed', to: 'feed#index'

# Auth
devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }

# Profile
resource :profile, only: [:edit, :update]
get '/u/:username', to: 'profiles#show', as: :user_profile
post '/u/:username/follow', to: 'follows#create'
delete '/u/:username/follow', to: 'follows#destroy'

# Core
resources :weekly_digests, only: [:index, :show, :new, :create, :edit, :update] do
  member { patch :publish; patch :unpublish }
end
resources :entries, only: [:index, :new, :create, :destroy]
resources :prompt_dispatches, only: [] do
  member { patch :skip }
end
```

---

## Key Technical Decisions & Gotchas

### Tailwind v4
- CSS-first config — **no `tailwind.config.js`**. All tokens live in `app/assets/tailwind/application.css` under `@theme`.
- Stylesheet name is `tailwind` (not `application`): `stylesheet_link_tag "tailwind"`

### OmniAuth 2.1.x CSRF
- OmniAuth 2.1.x has a built-in `AuthenticityTokenProtection` middleware
- Setting `OmniAuth.config.request_validation_phase = nil` does NOT disable it (nil-guard in source)
- **Fix in place:** `OmniAuth.config.request_validation_phase = ->(env) {}` (no-op lambda)
- Also: `OmniAuth.config.allowed_request_methods = %i[post]` and `silence_get_warning = true`
- OAuth buttons use `data: { turbo: false }` — Turbo intercepts button_to POSTs as fetch(), breaking the OAuth redirect

### Active Storage / S3
- `aws-sdk-s3` must be in the **main gem group** (not development/test) — production won't install dev/test gems
- `config.active_storage.service = :amazon` in `production.rb`

### Production (Render)
- URL: `https://weekbook.onrender.com`
- Ruby native environment (not Docker)
- Build command: `bundle install && bundle exec rails assets:precompile && bundle exec rails db:migrate`
- Start command: `bundle exec rails server -b 0.0.0.0 -p $PORT`
- Health check: `https://weekbook.onrender.com/up` (Rails 7.1 built-in)
- `RAILS_ENV` must be lowercase `production` (not `PRODUCTION`)
- `RAILS_MASTER_KEY` set as env var (no credentials file on server)

### Required Render env vars
```
RAILS_ENV=production
RAILS_MASTER_KEY=...
DATABASE_URL=...           # Render internal PostgreSQL URL
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=...
AWS_S3_BUCKET=...
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
GITHUB_CLIENT_ID=...
GITHUB_CLIENT_SECRET=...
```
**Not yet needed (add for Phase 6):**
```
REDIS_URL=...              # Render internal Redis URL — add when wiring Sidekiq
OPENAI_API_KEY=...         # Phase 6
TELNYX_API_KEY=...         # Phase 7
TELNYX_PHONE_NUMBER=...    # Phase 7
TELNYX_PUBLIC_KEY=...      # Phase 7 (optional — for webhook signature verification)
```

### Seeds
- Run `bundle exec rails db:seed` once on production after first deploy to load 22 prompt templates
- Seeds are idempotent (`find_or_create_by!`)

### Testing
- 91 specs, 0 failures (as of Phase 5)
- `spec/rails_helper.rb` has Devise test helpers (`include Devise::Test::IntegrationHelpers`)
- For request specs testing auth-protected routes: `sign_in user` / `sign_out user`
- In request specs, `ActiveRecord::RecordNotFound` is caught by Rails and returns 404 — test with `have_http_status(:not_found)`, not `raise_error`

---

## Build Status

### Merged to main / deployed
| | Feature | Notes |
|---|---|---|
| ✅ | Rails foundation + Devise auth | Email + password |
| ✅ | User profiles (`/u/:username`) | Avatar upload, bio, display name |
| ✅ | Social graph (follows/followers) | Follow button on profiles |
| ✅ | Avatar uploads | ActiveStorage + S3 |
| ✅ | OAuth (Google + GitHub) | Identity model, callback controller, CSRF fix |
| ✅ | Design system | Tailwind v4, cream/amber/ink palette, Fraunces + Inter |
| ✅ | WeeklyDigest | Draft/publish workflow, profile digest grid |
| ✅ | Entries | Private raw inputs, char-count controller, Turbo Streams |
| ✅ | Prompt system | PromptTemplate + PromptDispatch, 22 seeded prompts |
| ✅ | Feed | Published digests from followed users, follow suggestions |
| ✅ | Mobile | Hamburger nav, responsive padding, auth page fixes |

### Merged to main
All PRs #1–#13 are merged and live on main.

### Pending merge (PRs open, tests passing)
| Branch | PR | Feature | Merge order |
|---|---|---|---|
| `feat/ai-summarization` | PR15 | AI digest generation (Sidekiq + GPT-4o) | **Merge first** |
| `feat/polish` | PR14 | Pundit auth, branded error pages, OG meta, N+1 fixes | **Merge second** |
| `feat/ci` | PR16 | GitHub Actions CI, pre-push hooks, Brakeman, bundle-audit | **Merge third** |

> After merging feat/ai-summarization: add `REDIS_URL`, `OPENAI_API_KEY`, and Sidekiq worker service to Render before the feature activates.

### Not yet started
| Phase | Feature | Blocker/Notes |
|---|---|---|
| 7 | SMS ingestion via Twilio (inbound texts → entries) | Needs Twilio account + phone number |

---

## Phase 6 Pre-work (before starting AI summarization)
1. Create a Render Redis instance → copy internal URL → add `REDIS_URL` env var
2. Add a second Render service (worker): start command `bundle exec sidekiq`
3. Add `OPENAI_API_KEY` env var
4. Wire Sidekiq in `config/application.rb`: `config.active_job.queue_adapter = :sidekiq`

---

## Phase 7 Pre-work (before starting SMS)
1. Create Twilio account → purchase a phone number
2. Set `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_PHONE_NUMBER` env vars
3. Configure Twilio webhook URL: `https://weekbook.onrender.com/webhooks/twilio`

---

## Conventions

- All Ruby files: `# frozen_string_literal: true`
- Controllers: `before_action :authenticate_user!` on all protected actions
- Owner-scoped finds: `current_user.entries.find(params[:id])` — scopes to owner, raises 404 for others
- Turbo Streams used for create/destroy on entries (no full page reload)
- Week boundaries: always Monday 00:00 via `date.beginning_of_week(:monday)`
- Week number: `date.cweek` (ISO week, 1–53)
- Status fields: plain strings with `inclusion` validation, not enums
- Factories use `sequence` for uniqueness-constrained fields (email, username)
