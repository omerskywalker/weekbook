# frozen_string_literal: true

FactoryBot.define do
  factory :prompt_template do
    sequence(:body) { |n| "What was the highlight of your week? (#{n})" }
    category { 'highlight' }
    active { true }

    trait :reflection do
      category { 'reflection' }
      body { 'What surprised you most this week?' }
    end

    trait :inactive do
      active { false }
    end
  end
end
