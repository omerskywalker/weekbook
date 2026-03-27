# frozen_string_literal: true

FactoryBot.define do
  factory :entry do
    association :user
    content { 'Had a great standup today, the team shipped the auth feature ahead of schedule.' }
    week_start_date { Date.current.beginning_of_week(:monday) }

    trait :last_week do
      week_start_date { 1.week.ago.to_date.beginning_of_week(:monday) }
    end

    trait :short do
      content { 'Quick note.' }
    end
  end
end
