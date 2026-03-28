# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PromptDispatch, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(build(:prompt_dispatch)).to be_valid
    end

    it 'prevents two dispatches for the same user and week' do
      dispatch = create(:prompt_dispatch)
      duplicate = build(:prompt_dispatch, user: dispatch.user,
                                          week_start_date: dispatch.week_start_date)
      expect(duplicate).not_to be_valid
    end

    it 'allows different users to have dispatches for the same week' do
      dispatch = create(:prompt_dispatch)
      other = build(:prompt_dispatch, week_start_date: dispatch.week_start_date)
      expect(other).to be_valid
    end
  end

  describe '.for_current_week' do
    let(:user) { create(:user) }

    context 'when no dispatch exists for this week' do
      it 'creates a new dispatch when templates are available' do
        create(:prompt_template)
        expect { PromptDispatch.for_current_week(user) }.to change(PromptDispatch, :count).by(1)
      end

      it 'returns nil when no active templates exist' do
        expect(PromptDispatch.for_current_week(user)).to be_nil
      end
    end

    context 'when a dispatch already exists for this week' do
      it 'returns the existing dispatch without creating a new one' do
        existing = create(:prompt_dispatch, user: user)
        expect { PromptDispatch.for_current_week(user) }.not_to change(PromptDispatch, :count)
        expect(PromptDispatch.for_current_week(user)).to eq(existing)
      end
    end
  end

  describe '#pending?' do
    it 'returns true for pending status' do
      expect(build(:prompt_dispatch, status: 'pending').pending?).to be true
    end

    it 'returns false for skipped status' do
      expect(build(:prompt_dispatch, :skipped).pending?).to be false
    end
  end

  describe '#skip!' do
    it 'updates status to skipped' do
      dispatch = create(:prompt_dispatch)
      dispatch.skip!
      expect(dispatch.reload.status).to eq('skipped')
    end
  end
end
