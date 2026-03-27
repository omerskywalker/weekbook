# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Entry, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(build(:entry)).to be_valid
    end

    it 'requires content' do
      expect(build(:entry, content: '')).not_to be_valid
    end

    it 'requires content to be at least 5 characters' do
      expect(build(:entry, content: 'hi')).not_to be_valid
    end

    it 'requires content to be at most 500 characters' do
      expect(build(:entry, content: 'a' * 501)).not_to be_valid
    end

    it 'requires a user' do
      expect(build(:entry, user: nil)).not_to be_valid
    end
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let(:this_monday) { Date.current.beginning_of_week(:monday) }
    let(:last_monday) { 1.week.ago.to_date.beginning_of_week(:monday) }

    before do
      create(:entry, user: user, week_start_date: this_monday)
      create(:entry, user: user, week_start_date: last_monday, content: 'Last week entry here.')
    end

    it 'for_week returns only entries for that week' do
      results = user.entries.for_week(Date.current)
      expect(results.count).to eq(1)
      expect(results.first.week_start_date).to eq(this_monday)
    end

    it 'recent orders newest first' do
      create(:entry, user: user)
      results = user.entries.for_week(Date.current).recent
      expect(results.first.created_at).to be >= results.last.created_at
    end
  end

  describe '#this_week?' do
    it 'returns true for an entry from this week' do
      expect(build(:entry).this_week?).to be true
    end

    it 'returns false for an entry from last week' do
      expect(build(:entry, :last_week).this_week?).to be false
    end
  end

  describe 'before_validation' do
    it 'sets week_start_date to current Monday if blank' do
      entry = build(:entry, week_start_date: nil)
      entry.valid?
      expect(entry.week_start_date).to eq(Date.current.beginning_of_week(:monday))
    end
  end
end
