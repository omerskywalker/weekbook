# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.2.2'

gem 'rails', '~> 7.1.2'

# Database
gem 'pg', '~> 1.1'

# Web server
gem 'puma', '>= 5.0'

# Asset + JS
gem 'importmap-rails'
gem 'sprockets-rails'

# Hotwire
gem 'stimulus-rails'
gem 'turbo-rails'

# Styling
gem 'tailwindcss-rails'

# Auth
gem 'devise'

# Authorization
gem 'pundit'

# View components
gem 'view_component'

# JSON rendering
gem 'jbuilder'

# Background jobs
gem 'sidekiq'

# Redis (used by Sidekiq later)
gem 'redis', '~> 5.0'

# File uploads / image variants
gem 'image_processing', '~> 1.2'

# SMS integration
gem 'twilio-ruby'

# AI summarization
gem 'ruby-openai'

# ENV management
gem 'dotenv-rails'

# Boot performance
gem 'bootsnap', require: false

# Timezone for Windows
gem 'tzinfo-data', platforms: %i[windows jruby]

group :development, :test do
  # Debugging
  gem 'debug', platforms: %i[mri windows]

  # Testing
  gem 'factory_bot_rails'
  gem 'rspec-rails'
end

group :development do
  gem 'bullet'
  gem 'foreman'
  gem 'letter_opener'
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'web-console'
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
end
