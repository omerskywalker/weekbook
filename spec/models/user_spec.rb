# frozen_string_literal: true

require 'rails_helper'
require 'omniauth'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'rejects malformed usernames' do
      user = build(:user, username: 'bad username!')

      expect(user).not_to be_valid
      expect(user.errors[:username]).to include('only allows letters, numbers, and underscores')
    end

    it 'allows blank username' do
      user = build(:user, username: nil)

      expect(user).to be_valid
    end
  end

  describe '#name_for_display' do
    it 'prefers display_name' do
      user = build(:user, display_name: 'Omer', username: 'omer123', email: 'omer@example.com')

      expect(user.name_for_display).to eq('Omer')
    end

    it 'falls back to username' do
      user = build(:user, display_name: nil, username: 'omer123', email: 'omer@example.com')

      expect(user.name_for_display).to eq('omer123')
    end

    it 'falls back to email prefix' do
      user = build(:user, display_name: nil, username: nil, email: 'omer@example.com')

      expect(user.name_for_display).to eq('omer')
    end
  end

  describe '.from_omniauth' do
    let(:google_auth) do
      OmniAuth::AuthHash.new(
        provider: 'google_oauth2',
        uid: 'google-123',
        info: {
          email: 'omer@example.com'
        }
      )
    end

    it 'returns the existing user when identity already exists' do
      user = create(:user, email: 'omer@example.com')
      create(:identity, user: user, provider: 'google_oauth2', uid: 'google-123')

      result = described_class.from_omniauth(google_auth)

      expect(result).to eq(user)
      expect(Identity.count).to eq(1)
    end

    it 'links to an existing user by email when no identity exists' do
      user = create(:user, email: 'omer@example.com')

      result = described_class.from_omniauth(google_auth)

      expect(result).to eq(user)
      expect(user.identities.find_by(provider: 'google_oauth2', uid: 'google-123')).to be_present
    end

    it 'creates a new user when no matching user exists' do
      expect do
        @result = described_class.from_omniauth(google_auth)
      end.to change(described_class, :count).by(1)
                                            .and change(Identity, :count).by(1)

      expect(@result.email).to eq('omer@example.com')
      expect(@result.identities.find_by(provider: 'google_oauth2', uid: 'google-123')).to be_present
    end

    it 'raises when the provider does not return an email' do
      auth = OmniAuth::AuthHash.new(
        provider: 'github',
        uid: 'github-123',
        info: { email: nil }
      )

      expect { described_class.from_omniauth(auth) }
        .to raise_error(ArgumentError, 'OAuth provider did not supply an email')
    end
  end
end
