# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EntryPolicy do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:entry) { create(:entry, user: user) }

  describe 'destroy?' do
    it 'allows owner' do
      expect(described_class.new(user, entry).destroy?).to be true
    end

    it 'denies non-owner' do
      expect(described_class.new(other_user, entry).destroy?).to be false
    end
  end
end
