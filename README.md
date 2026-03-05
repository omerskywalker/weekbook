# Weekbook

Weekbook is a calm, authenticity-first social app.

Instead of crafting posts, you reply to short prompts (via SMS) throughout the week. Weekbook stores those raw updates privately, then generates a weekly public digest — a clean summary (and selected photos) that appears on your profile grid for followers to read.

## Tech Stack

- Ruby 3.2 / Rails 7.1
- PostgreSQL
- Hotwire (Turbo + Stimulus)
- ViewComponent
- Tailwind CSS

## Core Concepts

- **Entries**: private, raw check-ins (text/photos)
- **Weekly Wraps**: public weekly summaries generated from entries
- **Follows**: see weekly wraps from people you follow

## Development

### Prereqs
- Ruby 3.2
- Rails 7.1
- PostgreSQL

### Setup
```bash
# clone
git clone <your-repo-url>
cd wrapbook

# install deps
bundle install

# db
bin/rails db:create db:migrate

# run
bin/dev
