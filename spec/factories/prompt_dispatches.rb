# frozen_string_literal: true

FactoryBot.define do
  factory :prompt_dispatch do
    association :user
    association :prompt_template
    dispatched_at { Time.current }
    status { 'pending' }
    week_start_date { Date.current.beginning_of_week(:monday) }

    trait :responded do
      status { 'responded' }
    end

    trait :skipped do
      status { 'skipped' }
    end
  end
end
