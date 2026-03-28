# frozen_string_literal: true

class PhoneVerificationsController < ApplicationController
  before_action :authenticate_user!

  def new; end

  def create
    phone = PhoneUtils.normalize(params[:phone])

    if phone.blank?
      flash.now[:alert] = 'Please enter a valid phone number.'
      render :new, status: :unprocessable_content
      return
    end

    if User.where.not(id: current_user.id).exists?(phone: phone, phone_verified: true)
      flash[:alert] = 'That number is already linked to another account.'
      render :new, status: :unprocessable_content
      return
    end

    current_user.update!(phone: phone)
    current_user.send_verification_sms!
    redirect_to verify_phone_verification_path, notice: 'Code sent! Check your texts.'
  end

  def verify
    @sent_at = current_user.phone_verification_sent_at
  end

  def confirm
    if current_user.verify_phone!(params[:code])
      redirect_to edit_profile_path,
                  notice: 'Phone verified! You can now receive weekly prompts by text.'
    else
      flash[:alert] = 'Invalid or expired code. Try again.'
      render :verify, status: :unprocessable_content
    end
  end
end
