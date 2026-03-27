# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WeeklyDigest, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      digest = build(:weekly_digest)
      expect(digest).to be_valid
    end

    it 'requires week_start_date' do
      digest = build(:weekly_digest, week_start_date: nil)
      expect(digest).not_to be_valid
    end

    it 'requires a valid status' do
      digest = build(:weekly_digest, status: 'invalid')
      expect(digest).not_to be_valid
    end

    it 'prevents duplicate digest for the same user and week' do
      user = create(:user)
      create(:weekly_digest, user: user)
      duplicate = build(:weekly_digest, user: user)
      expect(duplicate).not_to be_valid
    end

    it 'allows different users to have digests for the same week' do
      create(:weekly_digest)
      other = build(:weekly_digest)
      expect(other).to be_valid
    end
  end

  describe '.for_week' do
    it 'returns the Monday of the given date' do
      wednesday = Date.new(2026, 3, 25)
      digest = described_class.for_week(wednesday)
      expect(digest.week_start_date).to eq(Date.new(2026, 3, 23))
    end

    it 'sets week_number correctly' do
      date = Date.new(2026, 3, 23)
      digest = described_class.for_week(date)
      expect(digest.week_number).to eq(date.cweek)
    end
  end

  describe '#week_range_label' do
    it 'returns a formatted date range string' do
      digest = build(:weekly_digest, week_start_date: Date.new(2026, 3, 23))
      expect(digest.week_range_label).to eq('Mar 23 – Mar 29')
    end
  end

  describe '#publish! / #unpublish!' do
    it 'publishes a draft digest' do
      digest = create(:weekly_digest)
      digest.publish!
      expect(digest.reload.status).to eq('published')
    end

    it 'unpublishes a published digest' do
      digest = create(:weekly_digest, :published)
      digest.unpublish!
      expect(digest.reload.status).to eq('draft')
    end
  end

  describe 'scopes' do
    it '.published returns only published digests' do
      create(:weekly_digest, :published)
      create(:weekly_digest)
      expect(described_class.published.count).to eq(1)
    end

    it '.recent orders by week_start_date descending' do
      old = create(:weekly_digest, :for_last_week)
      new_digest = create(:weekly_digest, user: create(:user))
      expect(described_class.recent.first).to eq(new_digest)
      expect(described_class.recent.last).to eq(old)
    end
  end
end
