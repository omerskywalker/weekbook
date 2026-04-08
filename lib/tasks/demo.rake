# frozen_string_literal: true

namespace :db do
  namespace :seed do
    desc 'Seed demo data for local development only'
    task demo: :environment do
      abort 'Cannot run demo seeds in production!' if Rails.env.production?
      load Rails.root.join('db/seeds/demo.rb')
      puts 'Demo seed complete.'
    end
  end
end
