# frozen_string_literal: true

class FollowsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def create
    current_user.active_follows.create!(followed: @user)
    redirect_to user_profile_path(@user.username), notice: 'Followed user.'
  rescue ActiveRecord::RecordInvalid
    redirect_to user_profile_path(@user.username), alert: 'Unable to follow user.'
  end

  def destroy
    current_user.active_follows.find_by(followed: @user)&.destroy
    redirect_to user_profile_path(@user.username), notice: 'Unfollowed user.'
  end

  private

  def set_user
    @user = User.find_by!(username: params[:username])
  end
end