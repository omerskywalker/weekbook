source "https://rubygems.org"

ruby "3.2.2"

gem "rails", "~> 7.1.2"

# Database
gem "pg", "~> 1.1"

# Web server
gem "puma", ">= 5.0"

# Asset + JS
gem "sprockets-rails"
gem "importmap-rails"

# Hotwire
gem "turbo-rails"
gem "stimulus-rails"

# Styling
gem "tailwindcss-rails"

# Auth
gem "devise"

# Authorization
gem "pundit"

# View components
gem "view_component"

# JSON rendering
gem "jbuilder"

# Background jobs
gem "sidekiq"

# Redis (used by Sidekiq later)
gem "redis", "~> 5.0"

# File uploads / image variants
gem "image_processing", "~> 1.2"

# SMS integration
gem "twilio-ruby"

# AI summarization
gem "ruby-openai"

# ENV management
gem "dotenv-rails"

# Boot performance
gem "bootsnap", require: false

# Timezone for Windows
gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development, :test do
  # Debugging
  gem "debug", platforms: %i[ mri windows ]

  # Testing
  gem "rspec-rails"
  gem "factory_bot_rails"
end

group :development do
  gem "web-console"
  gem "foreman"
  gem "letter_opener"
  gem "bullet"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end