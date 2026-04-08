# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Entries', type: :request do
  let(:user) { create(:user) }

  describe 'GET /entries' do
    context 'when signed in' do
      before { sign_in user }

      it 'returns 200' do
        get entries_path
        expect(response).to have_http_status(:ok)
      end

      context 'with a prompt dispatch for today' do
        let(:template) { create(:prompt_template, body: 'What made you smile today?') }
        let!(:dispatch) do
          create(:prompt_dispatch, user: user, prompt_template: template, date: Date.current)
        end

        it "shows today's prompt card" do
          get entries_path
          expect(response.body).to include("today's prompt")
          expect(response.body).to include('What made you smile today?')
        end
      end

      context 'without a prompt dispatch for today' do
        it 'does not show the prompt card' do
          get entries_path
          expect(response.body).not_to include("today's prompt")
        end
      end

      context 'when a draft digest exists for the current week' do
        let!(:digest) do
          create(:weekly_digest, user: user, status: 'draft',
                                 week_start_date: Date.current.beginning_of_week(:monday))
        end
        let!(:entry) { create(:entry, user: user) }

        it 'shows the soft draft message' do
          get entries_path
          expect(response.body).to include('is being prepared')
          expect(response.body).to include("Week #{Date.current.cweek}")
        end
      end

      it 'does not show the generate digest button' do
        get entries_path
        expect(response.body).not_to include('Generate this week&#39;s digest')
        expect(response.body).not_to include('generate_weekly_digest')
      end
    end

    context 'when signed out' do
      it 'redirects to sign in' do
        get entries_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET /entries/new' do
    before { sign_in user }

    it 'returns 200' do
      get new_entry_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /entries' do
    before { sign_in user }

    context 'with valid params' do
      it 'creates an entry and redirects' do
        expect do
          post entries_path,
               params: { entry: { content: 'Shipped the search feature today, feels good.' } }
        end.to change(Entry, :count).by(1)
        expect(response).to redirect_to(entries_path)
      end

      it 'sets week_start_date to current Monday' do
        post entries_path,
             params: { entry: { content: 'Shipped the search feature today, feels good.' } }
        expect(Entry.last.week_start_date).to eq(Date.current.beginning_of_week(:monday))
      end
    end

    context 'with invalid params' do
      it 'does not create an entry and renders index' do
        expect do
          post entries_path, params: { entry: { content: 'hi' } }
        end.not_to change(Entry, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'when signed out' do
      before { sign_out user }

      it 'redirects to sign in' do
        post entries_path,
             params: { entry: { content: 'Shipped the search feature today, feels good.' } }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'DELETE /entries/:id' do
    before { sign_in user }

    let!(:entry) { create(:entry, user: user) }

    it 'destroys the entry and redirects' do
      expect do
        delete entry_path(entry)
      end.to change(Entry, :count).by(-1)
      expect(response).to redirect_to(entries_path)
    end

    context 'when the entry belongs to another user' do
      let(:other_entry) { create(:entry) }

      it 'returns not found' do
        delete entry_path(other_entry)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
