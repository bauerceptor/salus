source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.4.9"
gem "rails", "~> 8.0"

# Cool stuff
gem "puma", "~> 6.0"
gem "propshaft"
gem "dartsass-rails"
gem "tzinfo-data", "~> 2.0.6", platforms: %i[mingw mswin x64_mingw jruby]
gem "bootsnap", "~> 1.18", require: false

# Enable importmaps support
gem "importmap-rails", "~> 2.0"

# Hotwire
gem "turbo-rails", "~> 1.4"
gem "stimulus-rails", "~> 1.3"

# Components
gem "view_component", "~> 3.0"
gem "view_component-contrib", "~> 0.2"

# Solid (Redis replacement for Rails 8)
gem "solid_queue"
gem "solid_cache"
gem "solid_cable"

# DSL for json structures
gem "jbuilder", "~> 2.12"

# Tailwind CSS support
gem "tailwindcss-rails", "~> 3.0"

# Load environment variables
gem "dotenv-rails", "~> 3.0"

# Authentication
gem "bcrypt", "~> 3.1"

# Authorization
gem "pundit", "~> 2.5"

# Annotate models with database schema (temporarily disabled - needs Rails 8 compatible version)
# gem "annotate"

# Validations
gem "phonelib", "~> 0.8"

# File uploads
gem "shrine", "~> 3.5"

# ERB Formatter
gem "htmlbeautifier", "~> 1.4"

# For profiling
gem "rack-mini-profiler", "~> 4.0"

# For memory profiling
gem "memory_profiler", "~> 1.0"

# For call-stack profiling flamegraphs
gem "stackprof", "~> 0.2"

# Fix for Ruby 3.4+ where mutex_m was removed from stdlib
gem "mutex_m"

# Pagination
gem "pagy", "~> 9.0"

# Charts
gem "chartkick", "~> 5.0"

# Calendar
gem "simple_calendar", "~> 2.4"

# Extended rake stats command
gem "rails_stats", "~> 1.0"

# Admin panel
gem "avo", "~> 2.50"

# Dynamically apply scopes
gem "has_scope", "~> 0.9"

# PDF generation
gem "prawn", "~> 2.5"
gem "prawn-table", "~> 0.2"

group :development, :test do
  gem "pg", "~> 1.5"
  gem "web-console", "~> 4.2"
  gem "debug", "~> 1.9", platforms: %i[mri mingw x64_mingw]
  gem "faker", "~> 3.0"
  gem "factory_bot_rails", "~> 6.4"
  gem "rspec-rails", "~> 7.0"
  gem "rubocop", "~> 1.65", require: false
  gem "rubocop-performance", "~> 1.22", require: false
  gem "rubocop-rails", "~> 2.30", require: false
  gem "rubocop-rake", "~> 0.6", require: false
  gem "rubocop-rspec", "~> 3.0", require: false
  gem "simplecov", "~> 0.22", require: false
  gem "rails-erd", "~> 1.7"
  gem "shoulda-matchers", "~> 6.0"
  gem "test-prof", "~> 1.0"
end

group :test do
  gem "sqlite3", "~> 2.0"
  gem "capybara"
  gem "selenium-webdriver", "~> 4.8"
  gem "rails-controller-testing"
  gem "database_cleaner"
end

gem "fhir_client", "~> 6.1"
gem "fhir_models", "~> 5.0"

# Inline SVG support
gem "inline_svg"

# Image processing for ActiveStorage variants
gem "image_processing", "~> 1.2"

# OTP / 2FA
gem "rotp", "~> 6.0"
gem "rqrcode", "~> 2.1"

# AI Agent
gem "ruby_llm", "~> 1.0"
