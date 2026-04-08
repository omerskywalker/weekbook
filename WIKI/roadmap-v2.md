---
type: roadmap
tags: [weekbook, v2, product, roadmap]
last-updated: 2026-04-08
---

# Weekbook — v2 Product Roadmap

> This document captures the v2 vision: elevating the AI output quality, deepening the personal feel, and removing every point of friction between a user's week and their published story.
>
> v1 proved the loop works. v2 makes the loop feel like it was made for you.

---

## North star

The weekly digest is the product. Everything else — SMS prompts, entries, AI summarization, the feed — exists to make that digest more honest, more personal, and more worth reading. v2 enhancements should be evaluated against one question: **does this make the digest feel more like the person who lived that week?**

---

## Enhancement list

---

### 1. Richer narrative prompting

**What:** Elevate the AI system prompt to use temporal context intentionally. Right now entries are passed as a list and GPT-4o is asked for 2–3 paragraphs. The output is competent but generic — it doesn't feel grounded in *when* things happened.

**What to change:**
- Pass each entry with its day of week and relative position in the week ("Monday", "midweek", "Friday")
- The system prompt already receives `Q: / A:` pairs via `prompt_text` — add an explicit instruction to weave the arc of the week into the narrative (how things shifted from early to late in the week)
- Infer a light "mood signal" per entry (positive/reflective/bittersweet) from word choice and feed it as a hint to the model — this doesn't need to be its own ML task, a short GPT call to classify can do it
- Instruct the model to write in a specific temporal rhythm: open with where the week started, close with where it ended

**Why it matters:** The temporal arc is what separates a weekly story from a list of nice things. The data is already there — this is a prompt engineering task, not a feature build.

**Effort:** Low — changes in `OpenaiSummarizer` only. No schema changes.

---

### 2. Tone and voice controls per user

**What:** Let users set a writing style preference that gets injected into the system prompt. Options: `reflective` (default), `playful`, `poetic`, `matter-of-fact`.

**Implementation:**
- Add `digest_tone` string column to `users` (default: `reflective`)
- Profile edit UI: 4-option picker with a brief example line under each
- `OpenaiSummarizer` reads `user.digest_tone` and prepends tone instruction to system prompt
- Example injection: `"Write in a playful, warm voice — conversational, a little funny, like someone telling a good story at a dinner table."`

**Why it matters:** Right now every digest sounds like the same AI. The entries are personal; the voice should be too. This is a low-effort config that makes the product feel custom-built for each person.

**Effort:** Low — one migration, one UI control, one conditional in the summarizer.

---

### 3. Regeneration with direction

**What:** After the AI generates a digest draft, let the user give a one-line nudge and regenerate. "Make it shorter." "More personal." "Focus on the work stuff." "Less introspective."

**Implementation:**
- Add a "Regenerate" button + text input on the digest edit page
- `POST /weekly_digests/:id/regenerate` — accepts a `direction` param
- `DigestSummarizerJob` accepts optional `direction` string, appended to the user prompt as: `"The user's note: #{direction}. Incorporate this direction into the revised narrative."`
- Saves the new version, keeps the user on the edit page

**Why it matters:** Hand-editing AI prose is friction. One-shot redirection is much lower effort and keeps the user trusting the AI layer rather than fighting it. It also surfaces intent — what people ask for tells you a lot about what the AI is getting wrong.

**Effort:** Medium — new route + action, job update, UI addition.

---

### 4. Quick-capture PWA

**What:** A minimal mobile-first web view designed for quick, unprompted entry at any time of day — not just in response to the 2pm SMS. Installable as a PWA (home screen icon, no browser chrome).

**Implementation:**
- Dedicate `/quick` as a stripped-down entry route: just a large text field and a submit button, no nav, no sidebar
- Add `manifest.json` + service worker for PWA installability
- Home screen install prompt on the entries index for mobile users who haven't installed
- The entry still lands in the current week's pool — no special handling needed

**Why it matters:** The 2pm SMS is the primary touchpoint but life doesn't happen at 2pm. The quick-capture PWA closes the gap without requiring a native app. The entries are the raw material for the digest — more entries, better digest.

**Effort:** Medium — new stripped view, PWA manifest, install prompt. No schema changes.

---

### 5. AI-generated digest cover image

**What:** Before publishing, generate an image that represents the mood or theme of the digest. Abstract, painterly, or illustrative. The generated text already exists — one more API call to DALL·E 3 or Flux produces a cover.

**Implementation:**
- "Generate cover image" button on the digest edit page
- `DigestCoverImageJob`: sends the digest `summary_line` + first paragraph to image API with a consistent style prompt ("soft watercolor, warm tones, no text, abstract")
- Store result via ActiveStorage on `WeeklyDigest`
- Render cover image on digest show page (top of card, like a magazine cover) and in the feed digest card

**Why it matters:** Profile grids and feeds are currently text-only. A cover image gives people a reason to click, makes profiles feel like a personal publication, and creates a shareable visual artifact of the week.

**Effort:** Medium-high — new job, ActiveStorage attachment on digest, image API integration, UI updates in feed and profile.

---

### 6. "What I noticed" highlight fragments

**What:** Alongside the narrative, have GPT return 2–3 short highlight phrases as JSON — things worth naming from the week. "This week I noticed: the light changing in the evenings / how good it felt to finish something / how much I miss cooking slowly."

**Implementation:**
- Add a second structured output call (or extend the existing call with `response_format: json_schema`) that returns `{ narrative: "...", highlights: ["...", "...", "..."] }`
- Store highlights in a `highlights` JSON column on `WeeklyDigest`
- Display as a styled block on the digest show page (amber dot list, distinct from the main narrative)
- Optional: one-tap share of a single highlight as plain text

**Why it matters:** Short fragments are the shareable unit. A 300-word narrative is harder to share than "this week I noticed: I'm actually pretty good at being patient." These highlights are the Twitter-friendly artifact the digest currently lacks — they extend the reach of the content without changing the writing.

**Effort:** Medium — schema addition, summarizer update (structured output), UI.

---

### 7. Archive as personal magazine

**What:** Transform the profile digest grid from a simple reverse-chronological list into a beautiful personal publication — visual year/month grouping, reading time, word count, a "this time last year" feature.

**Implementation:**
- Group digests by year on the profile page with a year header
- Add `reading_time` (computed: word count ÷ 200) displayed on each digest card
- "This time last year" section at the top of the profile when a digest exists for the same week of the prior year — surfaced as a soft nudge: "A year ago: [summary_line]"
- Optional: a `/[username]/[year]` archive view showing all digests for a given year as a magazine-style layout

**Why it matters:** The archive is the product's long-term value proposition. People return to Weekbook years later to remember who they were. Right now it looks like a grid of cards. It should feel like a personal publication you'd actually want to revisit.

**Effort:** Low-medium — mostly UI and view logic. No new data needed beyond what's stored.

---

### 8. Weekly friend digest email

**What:** Instead of (or in addition to) per-publish follower notifications, send a single weekly "your friends published this week" email — 3–5 digest summaries from people you follow, curated, with a link to read each.

**Implementation:**
- New `WeeklyFriendDigestJob` runs Monday mornings
- For each user: find all published digests from followed users in the past 7 days
- Skip if zero (no email for empty weeks)
- `DigestMailer#weekly_friend_digest(user, digests)` — renders summary cards inline
- Opt-out setting in profile: `receive_friend_digest_email` boolean

**Why it matters:** Per-publish emails are fine for high-signal follows, but as people follow more users, the inbox gets noisy. A curated weekly rollup respects attention and keeps passive readers engaged without overwhelming them. It's also a natural re-engagement mechanism for users who've drifted.

**Effort:** Medium — new job, new mailer template, one migration (opt-out flag), new cron.

---

### 9. Entry streaks and gentle accountability

**What:** A private streak counter on the entries dashboard. "12 days in a row" — no fanfare, just a quiet signal that you've been showing up. Also surfaced in the digest narrative: "You wrote something every day this week."

**Implementation:**
- Computed on the fly from `PromptDispatch` records: count consecutive days with a `responded` status
- Display as a small badge on the entries index ("🔥 12-day streak" in ink, not amber — keep it calm)
- `OpenaiSummarizer` receives the streak count and the system prompt includes a one-line note when the user wrote every day: "Note: the user replied to every prompt this week — acknowledge this briefly and naturally in the narrative."
- No leaderboards, no public visibility, no email about streaks. Private only.

**Why it matters:** The SMS prompt is the product's heartbeat. Streaks give people a soft reason to reply on a hard day without turning Weekbook into a productivity app. The key design constraint is that it must feel like a quiet observation, not a pressure mechanism.

**Effort:** Low — computed field, small UI addition, one-line change in the summarizer.

---

### 10. Phone verification onboarding audit

**What:** The SMS loop is the product's primary input mechanism. If users don't complete phone verification, they never activate the core experience. The current OTP flow works but hasn't been audited for conversion.

**Audit checklist:**
- Is the phone verification CTA visible and prominent after sign-up? Does it appear in a dismissable banner until verified?
- Is the OTP email clearly worded? Does it expire quickly enough to feel urgent, long enough to be usable?
- Is there a clear "resend code" path if the SMS doesn't arrive?
- What happens if the user enters an international number? (Current `PhoneUtils.normalize` assumes US +1 for 10-digit numbers — needs graceful handling or explicit US-only messaging)
- Is there a fallback path (web-only mode) that's still valuable enough to retain a user who can't or won't verify?

**Suggested changes:**
- Add "resend verification code" link on the verify page (currently absent)
- Add a persistent "activate SMS prompts" banner on entries index for unverified users
- Explicit UI copy: "US numbers only (for now)" to prevent confusion on international numbers
- Consider: after first sign-up, redirect to phone verification as a dedicated onboarding step rather than leaving it buried in profile edit

**Why it matters:** Every friction point in this flow is a direct conversion loss on the core loop. Fixing this has higher ROI than any new feature.

**Effort:** Low-medium — UI additions, one new route action (resend), copy changes.

---

## Additional suggestions

---

### 11. Digest reactions from followers

Simple, low-noise reactions on published digests — not likes, not comments. A small set of responses that feel like a nod from a friend: "this resonated", "made me smile", "thinking of you". No counts shown publicly (privacy-preserving), but the author gets a quiet notification. Keeps the social layer warm without enabling the performance dynamic the app is designed to avoid.

---

### 12. Entry media — photos and voice

Let users attach a photo or short voice memo to an entry (web UI only, not SMS). The photo gets passed as a URL in the OpenAI call (GPT-4o is multimodal); voice memos are transcribed before summarization. The digest becomes richer without requiring more text input. This fits the "low effort, high fidelity" principle: your week is more than words.

---

### 13. Seasonal and retrospective digests

Auto-generate quarterly and annual retrospectives from the stored digest content. "Your summer." "Your 2026." These are high-value artifacts that require no new input — just a second pass over existing digests with a different system prompt. Annual retrospectives in particular are exactly what keeps people using Weekbook years from now.

---

### 14. Collaborative digests

Let two users co-author a digest for a shared week — a couple, two friends, travel companions. Each contributes entries; the summarizer receives both sets and writes a shared narrative. The digest publishes to both profiles. This opens a new social primitive without changing the core single-user experience.

---

### 15. Exportable personal archive

Let users export their complete entry + digest history as a beautifully formatted PDF or ePub — a personal memoir artifact. This is the long-term value proposition made tangible. Someone who's used Weekbook for 3 years could print their archive. The data is already there; the export is presentation.

---

## Prioritization notes

**Ship first (low effort, high impact):**
- #1 Richer narrative prompting — pure prompt engineering, no schema changes
- #2 Tone/voice controls — one migration, big perceived value
- #9 Entry streaks — computed field, minor UI
- #10 Phone verification audit — conversion fix, not a feature

**Ship second (medium effort, core product):**
- #3 Regeneration with direction — closes the AI trust loop
- #7 Archive as personal magazine — makes the product feel permanent
- #8 Weekly friend digest email — retention mechanism

**Ship third (higher effort, product differentiation):**
- #4 Quick-capture PWA — expands the input surface
- #5 AI cover image — makes the product visual
- #6 Highlight fragments — creates shareable artifacts
- #11 Digest reactions — social layer without social media dynamics

**Longer horizon:**
- #12 Entry media (photos, voice)
- #13 Seasonal retrospectives
- #14 Collaborative digests
- #15 Exportable archive

---

## What NOT to build

- Comments on digests (defeats the authenticity-first design)
- Public entry visibility (the private/public separation is the entire point)
- Follower counts, like counts, or any public engagement metrics
- Daily posting (the weekly format is a deliberate constraint, not a limitation)
- Algorithmic feed ranking (chronological only — no engagement optimization)
