# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PromptTemplate, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(build(:prompt_template)).to be_valid
    end

    it 'requires body' do
      expect(build(:prompt_template, body: '')).not_to be_valid
    end

    it 'requires a valid category' do
      expect(build(:prompt_template, category: 'unknown')).not_to be_valid
    end

    it 'accepts all six supported categories' do
      %w[joy gratitude connection self memory anticipation].each do |cat|
        expect(build(:prompt_template, category: cat)).to be_valid
      end
    end

    it 'rejects legacy categories' do
      %w[reflection challenge highlight].each do |cat|
        expect(build(:prompt_template, category: cat)).not_to be_valid
      end
    end
  end

  describe '.random_for_week' do
    it 'returns an active template' do
      create(:prompt_template)
      create(:prompt_template, :inactive)
      result = PromptTemplate.random_for_week
      expect(result).to be_active
    end

    it 'returns nil when no active templates exist' do
      create(:prompt_template, :inactive)
      expect(PromptTemplate.random_for_week).to be_nil
    end
  end
end
