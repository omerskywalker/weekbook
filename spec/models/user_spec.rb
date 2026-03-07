# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  it 'is invalid with a malformed username' do
    user = User.new(
      email: 'test@example.com',
      password: 'password123',
      username: 'bad name!'
    )

    expect(user).not_to be_valid
  end
end
