# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Profiles", type: :request do
  let(:user) do
    User.create!(
      email: "omer@example.com",
      password: "password123",
      username: "omer",
      display_name: "Omer"
    )
  end

  describe "GET /u/:username" do
    it "returns success" do
      get user_profile_path(user.username)
      expect(response).to have_http_status(:success)
    end
  end
end
