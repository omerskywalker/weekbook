# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Identity, type: :model do
  describe 'validations' do
    it 'is valid with a user, provider, and uid' do
      identity = build(:identity)

      expect(identity).to be_valid
    end

    it 'requires a provider' do
      identity = build(:identity, provider: nil)

      expect(identity).not_to be_valid
      expect(identity.errors[:provider]).to include("can't be blank")
    end

    it 'requires a uid' do
      identity = build(:identity, uid: nil)

      expect(identity).not_to be_valid
      expect(identity.errors[:uid]).to include("can't be blank")
    end

    it 'enforces uid uniqueness scoped to provider' do
      create(:identity, provider: 'github', uid: '123')
      duplicate = build(:identity, provider: 'github', uid: '123')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:uid]).to include('has already been taken')
    end

    it 'allows the same uid for different providers' do
      create(:identity, provider: 'github', uid: '123')
      identity = build(:identity, provider: 'google_oauth2', uid: '123')

      expect(identity).to be_valid
    end
  end
end
