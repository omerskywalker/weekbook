# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { 'user@example.com' }
    password { 'password123' }
    username { 'testuser' }
    display_name { 'Test User' }
    bio { 'Test bio' }
  end
end
