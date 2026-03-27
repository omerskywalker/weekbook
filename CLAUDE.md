# Weekbook — Agent Context Pack

> Hand this file to any agent working on this codebase. It is the single source of truth for what has been built, what decisions were made, and what comes next.
> Last updated: 2026-03-27

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
TWILIO_ACCOUNT_SID=...     # Phase 7
TWILIO_AUTH_TOKEN=...      # Phase 7
TWILIO_PHONE_NUMBER=...    # Phase 7
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

### Pending merge (PRs open, tests passing)
| Branch | PR | Feature | Merge order |
|---|---|---|---|
| `feat/entries` | PR10 | Entry model, focused writing UI, char-count controller, Turbo Streams | **Merge first** |
| `feat/prompts` | PR11 | PromptTemplate + PromptDispatch, 22 seeds, prompt banner | **Merge second** |
| `feat/feed` | PR12 | Feed of published digests, follow suggestions, pagination | **Merge third** |

> **Important:** These three branches are chained (each cut from the previous). Merge in order.
> After merging, run `rails db:seed` on Render to load prompt templates.

### Not yet started
| Phase | Feature | Blocker/Notes |
|---|---|---|
| 6 | AI summarization (OpenAI → WeeklyDigest narrative, Sidekiq job) | Add `REDIS_URL` + `OPENAI_API_KEY` to Render before starting |
| 7 | SMS ingestion via Twilio (inbound texts → entries) | Needs Twilio account + phone number |
| 8 | Polish (ViewComponents, Pundit authz, N+1 fixes, OG meta) | No blockers |

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
