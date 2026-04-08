# frozen_string_literal: true

FactoryBot.define do
  factory :weekly_digest do
    association :user
    week_start_date { Date.current.beginning_of_week(:monday) }
    week_number { |d| d.week_start_date&.cweek || Date.current.cweek }
    year { |d| d.week_start_date&.cwyear || Date.current.cwyear }
    status { 'draft' }
    content { 'This week I worked on some interesting things.' }
    summary_line { 'A productive week.' }

    trait :published do
      status { 'published' }
    end

    trait :archived do
      status { 'archived' }
    end

    trait :for_last_week do
      week_start_date { 1.week.ago.to_date.beginning_of_week(:monday) }
    end
  end
end
