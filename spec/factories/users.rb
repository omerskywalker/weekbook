# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password123' }
    sequence(:username) { |n| "testuser#{n}" }
    display_name { 'Test User' }
    bio { 'Test bio' }
  end
end
