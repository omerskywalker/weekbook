# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Follow, type: :model do
  describe 'validations' do
    it 'is valid with a follower and followed user' do
      follower = create(:user)
      followed = create(:user)

      follow = described_class.new(follower:, followed:)

      expect(follow).to be_valid
    end

    it 'does not allow duplicate follows' do
      follower = create(:user)
      followed = create(:user)

      create(:follow, follower:, followed:)
      duplicate = build(:follow, follower:, followed:)

      expect(duplicate).not_to be_valid
    end

    it 'does not allow a user to follow themselves' do
      user = create(:user)
      follow = build(:follow, follower: user, followed: user)

      expect(follow).not_to be_valid
      expect(follow.errors[:followed_id]).to include('cannot be the same as follower')
    end
  end
end