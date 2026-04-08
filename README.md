# Weekbook

A calm, low-friction journaling app that turns your week into a story.

---

## What it does

Weekbook texts you a warm, friendly question every day — *"what made you smile today?" "what's something you'd like to remember this week?"* — and you reply honestly, knowing nothing gets posted anywhere automatically.

At the end of the week, your answers are gathered and sent to an AI that writes a first-person narrative from them. You get an email: your digest is ready. Review it, make any edits, and publish it to your profile — or turn on auto-publish and it happens without any action from you.

Followers see your published weekly digests in their feed. Your raw entries are always private, permanently.

**The core idea:** social media rewards performance. Weekbook rewards noticing. The raw entries never appear publicly — only the synthesized weekly story does.

---

## How it works

```
Daily cron (2pm)
  └─ SmsPromptJob → warm daily question via SMS to verified users

User replies to SMS  ──OR──  User writes via web UI
  └─ Entry saved (always private)
     stores: content + the question that prompted it

Sunday evening cron (8pm)
  └─ WeeklyDigestAutoGenerateJob
       └─ DigestSummarizerJob (per user)
            └─ OpenaiSummarizer → GPT-4o
                 └─ WeeklyDigest created (draft)

DigestMailer → owner email
  ├─ auto_publish off: "your digest is ready to review" + edit link
  └─ auto_publish on:  digest published + "your digest has been published"

User publishes digest
  └─ NotifyFollowersJob → DigestMailer → email all followers
       └─ Followers see digest in /feed
```

---

## Tech stack

| Layer | Technology |
|---|---|
| Framework | Rails 7.2, Ruby 3.2.2 |
| Database | PostgreSQL |
| Frontend | Tailwind CSS v4, Hotwire (Turbo + Stimulus) |
| Auth | Devise + OmniAuth (Google, GitHub) |
| File uploads | ActiveStorage + AWS S3 |
| Background jobs | Sidekiq + Redis |
| AI | ruby-openai → GPT-4o |
| SMS | Telnyx (`telnyx` gem) |
| Email | ActionMailer + Postmark (SMTP) |
| Testing | RSpec + FactoryBot |
| Deployment | Render (Ruby native) |
| CI | GitHub Actions — lint, security, tests in parallel |

---

## Local setup

### Prerequisites
- Ruby 3.2.2
- PostgreSQL
- Redis (for Sidekiq)

### Install and run

```bash
git clone https://github.com/omerskywalker/weekbook
cd weekbook

bundle install

bin/rails db:create db:migrate
bin/rails db:seed          # loads 55 daily prompt templates

bin/dev                    # starts Rails + Tailwind watcher together
```

> **Always use `bin/dev`**, not `rails server`. The Tailwind watcher must run alongside Rails or the CSS won't compile.

### Demo data

To preview the full UI with realistic data before real users arrive:

```bash
bundle exec rails db:seed:demo
```

This creates:
- Demo user: `demo@weekbook.dev` / `password` (display name: Alex Rivera)
- A follower: `jamie@weekbook.dev` / `password`
- 3 weeks of daily entries with warm prompts and human-like answers
- 2 published weekly digests + 1 draft for the current week
- Mutual follows so the feed is populated

**Production-safe:** the demo task raises immediately if `Rails.env.production?`. It is not called from `db/seeds.rb` and has zero impact on production deploys.

---

## Environment variables

Copy `.env.example` to `.env` for local development. Required in production:

```
# Core
RAILS_ENV=production
RAILS_MASTER_KEY=
DATABASE_URL=

# Auth
SECRET_KEY_BASE=
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GITHUB_CLIENT_ID=
GITHUB_CLIENT_SECRET=

# Storage
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=
AWS_S3_BUCKET=

# Background jobs
REDIS_URL=

# AI (digest generation)
OPENAI_API_KEY=

# SMS (Telnyx)
TELNYX_API_KEY=
TELNYX_PHONE_NUMBER=
TELNYX_PUBLIC_KEY=       # optional — for webhook signature verification

# Email (Postmark)
SMTP_HOST=smtp.postmarkapp.com
SMTP_PORT=587
SMTP_USERNAME=           # Postmark API token
SMTP_PASSWORD=           # same as SMTP_USERNAME
APP_HOST=                # e.g. weekbook.onrender.com
```

---

## Cron jobs (Render)

Two scheduled jobs run in production:

| Job | Command | Schedule | What it does |
|---|---|---|---|
| Daily prompt | `bundle exec rails runner "SmsPromptJob.perform_later"` | `0 14 * * *` | Texts one prompt to each verified user |
| Weekly digest | `bundle exec rails runner "WeeklyDigestAutoGenerateJob.perform_later"` | `0 20 * * 0` | Generates AI digest for all users with entries that week |

Build command for cron services: `bundle install`

---

## Design system

All tokens live in `app/assets/tailwind/application.css` under `@theme`. There is no `tailwind.config.js`.

| Token | Value | Use |
|---|---|---|
| `cream-50` → `cream-400` | `#fdfcf9` → `#d9cbb4` | Background surfaces |
| `ink-900` | `#0f0f0f` | Nav background, headings |
| `ink-300` → `ink-800` | — | Text hierarchy |
| `amber` | `#d4a853` | Primary accent — CTAs, week numbers |
| `amber-light` | `#e8c97a` | Hover state |
| `shadow-warm` | — | All card shadows |

Fonts: **Inter** (body) + **Fraunces** (display/headings — use `font-display` class). Loaded via Google Fonts in the layout.

The stylesheet is compiled to `app/assets/builds/tailwind.css` at runtime — that directory is gitignored, which is why `bin/dev` (not `rails server`) is required locally.

---

## Data model

| Model | Key fields | Notes |
|---|---|---|
| `User` | email, username, display_name, bio, auto_publish_digest | Devise + OmniAuth; avatar via ActiveStorage |
| `Entry` | user_id, content (5–500 chars), week_start_date, prompt_text | Always private; prompt_text stores the question that prompted this entry |
| `WeeklyDigest` | user_id, week_start_date, content, summary_line (≤160), status | draft / published / archived; one per user per week |
| `PromptTemplate` | body, category, active | 55 daily prompts across joy / gratitude / connection / self / memory / anticipation |
| `PromptDispatch` | user_id, date, week_start_date, prompt_template_id, status | One per user per day; pending / responded / skipped |
| `Follow` | follower_id, followed_id | Social graph |
| `Identity` | user_id, provider, uid | OAuth identity linking |

---

## Running tests

```bash
bundle exec rspec
```

CI runs three parallel jobs on every push and PR: **RuboCop** (lint), **Brakeman + bundle-audit** (security), and **RSpec** (full suite). All three must pass before merging.

To run locally before pushing:
```bash
bundle exec rubocop
bundle exec brakeman -q
bundle exec rspec
```

The pre-push hook (`.githooks/pre-push`) runs rubocop + rspec automatically. Activate once with:
```bash
bin/setup-hooks
```

---

## Deployment

Hosted on [Render](https://render.com). Three services:

| Service | Type | Start command |
|---|---|---|
| `weekbook` | Web | `bundle exec rails server -b 0.0.0.0 -p $PORT` |
| `weekbook-worker` | Background worker | `bundle exec sidekiq` |
| `weekbook-cron` | Cron | `bundle exec rails runner "SmsPromptJob.perform_later"` |
| `weekbook-digest-cron` | Cron | `bundle exec rails runner "WeeklyDigestAutoGenerateJob.perform_later"` |

Build command (web + worker): `bundle install && bundle exec rails assets:precompile && bundle exec rails db:migrate`

Build command (cron services): `bundle install`

Health check endpoint: `/up`

### First deploy checklist
- [ ] Set all environment variables above
- [ ] Run `bundle exec rails db:seed` once via the Render Shell (loads 55 prompt templates)
- [ ] Configure Telnyx number inbound webhook URL: `https://yourapp.onrender.com/webhooks/sms`
- [ ] Set Telnyx number's Messaging Profile in the Telnyx portal
- [ ] Verify SMTP by sending a test email

---

## SMS webhook

Telnyx sends inbound messages as JSON to `POST /webhooks/sms`. The controller:
- Extracts `data.payload.from.phone_number` and `data.payload.text`
- Matches the phone number to a verified user
- Creates an Entry (with today's prompt stored as `prompt_text`)
- Handles `SKIP` replies to skip the current day's prompt

Webhook signature verification is enabled when `TELNYX_PUBLIC_KEY` is set. Without it, the endpoint still works but skips signature checks (useful in development).
