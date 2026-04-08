# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PromptDispatch, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(build(:prompt_dispatch)).to be_valid
    end

    it 'prevents two dispatches for the same user and date' do
      dispatch = create(:prompt_dispatch)
      duplicate = build(:prompt_dispatch, user: dispatch.user, date: dispatch.date)
      expect(duplicate).not_to be_valid
    end

    it 'allows different users to have dispatches for the same date' do
      dispatch = create(:prompt_dispatch)
      other = build(:prompt_dispatch, date: dispatch.date)
      expect(other).to be_valid
    end

    it 'allows the same user to have dispatches on different dates' do
      dispatch = create(:prompt_dispatch, date: Date.current)
      second = build(:prompt_dispatch, user: dispatch.user, date: Date.current + 1)
      expect(second).to be_valid
    end
  end

  describe '.for_today' do
    let(:user) { create(:user) }

    context 'when no dispatch exists for today' do
      it 'creates a new dispatch when templates are available' do
        create(:prompt_template)
        expect { PromptDispatch.for_today(user) }.to change(PromptDispatch, :count).by(1)
      end

      it 'returns nil when no active templates exist' do
        expect(PromptDispatch.for_today(user)).to be_nil
      end

      it 'sets date to today' do
        create(:prompt_template)
        dispatch = PromptDispatch.for_today(user)
        expect(dispatch.date).to eq(Date.current)
      end

      it 'sets week_start_date to the Monday of this week' do
        create(:prompt_template)
        dispatch = PromptDispatch.for_today(user)
        expect(dispatch.week_start_date).to eq(Date.current.beginning_of_week(:monday))
      end
    end

    context 'when a dispatch already exists for today' do
      it 'returns the existing dispatch without creating a new one' do
        create(:prompt_template)
        existing = PromptDispatch.for_today(user)
        expect { PromptDispatch.for_today(user) }.not_to change(PromptDispatch, :count)
        expect(PromptDispatch.for_today(user)).to eq(existing)
      end
    end
  end

  describe '.for_current_week' do
    let(:user) { create(:user) }

    it 'returns a relation (not a single record)' do
      expect(PromptDispatch.for_current_week(user)).to be_a(ActiveRecord::Relation)
    end

    it 'returns all dispatches for the current week ordered by date' do
      monday = Date.current.beginning_of_week(:monday)
      template = create(:prompt_template)
      d1 = create(:prompt_dispatch, user: user, date: monday,
                                    week_start_date: monday, prompt_template: template)
      d2 = create(:prompt_dispatch, user: user, date: monday + 1,
                                    week_start_date: monday, prompt_template: template)
      result = PromptDispatch.for_current_week(user)
      expect(result).to eq([d1, d2])
    end

    it 'does not include dispatches from previous weeks' do
      last_monday = Date.current.beginning_of_week(:monday) - 7
      template = create(:prompt_template)
      create(:prompt_dispatch, user: user, date: last_monday,
                               week_start_date: last_monday, prompt_template: template)
      expect(PromptDispatch.for_current_week(user)).to be_empty
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
