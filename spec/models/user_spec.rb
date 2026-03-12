# frozen_string_literal: true

require 'rails_helper'

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
end
