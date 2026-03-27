# frozen_string_literal: true

class WeeklyDigestsController < ApplicationController
  before_action :authenticate_user!, except: %i[show]
  before_action :set_digest, only: %i[show edit update publish unpublish]
  before_action :require_owner!, only: %i[edit update publish unpublish]

  def index
    @digests = current_user.weekly_digests.recent
  end

  def show
    return if @digest.published? || (user_signed_in? && current_user == @digest.user)

    redirect_to root_path, alert: 'This digest is not published.'
  end

  def new
    @digest = WeeklyDigest.current_week(current_user)

    if @digest.persisted?
      redirect_to edit_weekly_digest_path(@digest), notice: 'A digest for this week already exists.'
    end
  end

  def create
    @digest = current_user.weekly_digests.build(digest_params)
    @digest.week_start_date = Date.current.beginning_of_week(:monday)
    @digest.week_number = @digest.week_start_date.cweek
    @digest.year = @digest.week_start_date.cwyear

    if @digest.save
      redirect_to edit_weekly_digest_path(@digest), notice: 'Digest created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @digest.update(digest_params)
      redirect_to weekly_digest_path(@digest), notice: 'Digest saved.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def publish
    @digest.publish!
    redirect_to weekly_digest_path(@digest), notice: 'Digest published.'
  end

  def unpublish
    @digest.unpublish!
    redirect_to weekly_digest_path(@digest), notice: 'Digest moved back to draft.'
  end

  private

  def set_digest
    @digest = WeeklyDigest.find(params[:id])
  end

  def require_owner!
    redirect_to root_path, alert: 'Not authorized.' unless current_user == @digest.user
  end

  def digest_params
    params.require(:weekly_digest).permit(:content, :summary_line)
  end
end
