# frozen_string_literal: true

class ProfilesController < ApplicationController
  before_action :authenticate_user!, only: %i[edit update]

  def show
    @user = User.find_by!(username: params[:username])
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(profile_params)
      redirect_to user_profile_path(@user.username), notice: "Profile updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def profile_params
    params.require(:user).permit(:username, :display_name, :bio)
  end
end
