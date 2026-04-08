# frozen_string_literal: true

FactoryBot.define do
  factory :prompt_template do
    sequence(:body) { |n| "what's something that made you smile this week? (#{n})" }
    category { 'joy' }
    active { true }

    trait :gratitude do
      category { 'gratitude' }
      body { "what's something small you're grateful for this week?" }
    end

    trait :inactive do
      active { false }
    end
  end
end
