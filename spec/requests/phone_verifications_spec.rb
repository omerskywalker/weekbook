# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PhoneVerifications', type: :request do
  let(:user) { create(:user) }

  before do
    allow(TwilioService).to receive(:send_sms!).and_return(nil)
  end

  describe 'GET /phone_verification/new' do
    context 'when signed out' do
      it 'redirects to sign in' do
        get new_phone_verification_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when signed in' do
      before { sign_in user }

      it 'returns 200' do
        get new_phone_verification_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'POST /phone_verification' do
    context 'when signed out' do
      it 'redirects to sign in' do
        post phone_verification_path, params: { phone: '+15551234567' }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when signed in' do
      before { sign_in user }

      context 'with a valid phone number' do
        it 'saves the phone number and sends an OTP' do
          expect(TwilioService).to receive(:send_sms!).once
          post phone_verification_path, params: { phone: '+15551234567' }
          expect(user.reload.phone).to eq('+15551234567')
        end

        it 'redirects to the verify page' do
          post phone_verification_path, params: { phone: '+15551234567' }
          expect(response).to redirect_to(verify_phone_verification_path)
        end

        it 'stores a verification code on the user' do
          post phone_verification_path, params: { phone: '+15551234567' }
          expect(user.reload.phone_verification_code).to be_present
        end
      end

      context 'with a 10-digit US number (without country code)' do
        it 'normalizes to E.164 and saves' do
          post phone_verification_path, params: { phone: '5551234567' }
          expect(user.reload.phone).to eq('+15551234567')
        end
      end

      context 'with an invalid phone number' do
        it 'does not save and re-renders the form' do
          post phone_verification_path, params: { phone: 'not-a-phone' }
          expect(response).to have_http_status(:unprocessable_content)
          expect(user.reload.phone).to be_blank
        end
      end

      context 'when number is already verified by another user' do
        before do
          create(:user, phone: '+15559876543', phone_verified: true)
        end

        it 'does not save and shows an error' do
          post phone_verification_path, params: { phone: '+15559876543' }
          expect(response).to have_http_status(:unprocessable_content)
          expect(user.reload.phone).to be_blank
        end
      end
    end
  end

  describe 'GET /phone_verification/verify' do
    context 'when signed out' do
      it 'redirects to sign in' do
        get verify_phone_verification_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when signed in' do
      before { sign_in user }

      it 'returns 200' do
        get verify_phone_verification_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'POST /phone_verification/confirm' do
    context 'when signed out' do
      it 'redirects to sign in' do
        post confirm_phone_verification_path, params: { code: '123456' }
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when signed in' do
      before do
        sign_in user
        user.update!(
          phone: '+15551234567',
          phone_verification_code: '654321',
          phone_verification_sent_at: Time.current
        )
      end

      context 'with the correct code' do
        it 'verifies the phone and redirects to profile edit' do
          post confirm_phone_verification_path, params: { code: '654321' }
          expect(user.reload.phone_verified).to be true
          expect(response).to redirect_to(edit_profile_path)
        end

        it 'clears the verification code' do
          post confirm_phone_verification_path, params: { code: '654321' }
          expect(user.reload.phone_verification_code).to be_nil
        end
      end

      context 'with an incorrect code' do
        it 'does not verify and re-renders the verify form' do
          post confirm_phone_verification_path, params: { code: '000000' }
          expect(user.reload.phone_verified).to be false
          expect(response).to have_http_status(:unprocessable_content)
        end
      end

      context 'with an expired code (sent more than 10 minutes ago)' do
        before do
          user.update!(phone_verification_sent_at: 11.minutes.ago)
        end

        it 'does not verify and re-renders the verify form' do
          post confirm_phone_verification_path, params: { code: '654321' }
          expect(user.reload.phone_verified).to be false
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end
  end
end
