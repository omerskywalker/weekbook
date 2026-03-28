# frozen_string_literal: true

class EntriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_entry, only: [:destroy]

  def index
    @week_start = Date.current.beginning_of_week(:monday)
    @entries = current_user.entries.for_week(@week_start).recent
    @entry = Entry.new
    @prompt = PromptDispatch.for_current_week(current_user)
    return unless @entries.any?

    @current_digest = current_user.weekly_digests.find_or_create_by(
      week_start_date: @week_start,
      week_number: @week_start.cweek,
      year: @week_start.cwyear
    )
  end

  def new
    @entry = Entry.new
    @week_start = Date.current.beginning_of_week(:monday)
    @prompt = PromptDispatch.for_current_week(current_user)
  end

  def create
    @entry = current_user.entries.build(entry_params)

    if @entry.save
      respond_to do |format|
        format.html { redirect_to entries_path, notice: 'Entry saved.' }
        format.turbo_stream
      end
    else
      @week_start = Date.current.beginning_of_week(:monday)
      @entries = current_user.entries.for_week(@week_start).recent
      render :index, status: :unprocessable_content
    end
  end

  def destroy
    authorize @entry
    @entry.destroy
    respond_to do |format|
      format.html { redirect_to entries_path, notice: 'Entry removed.' }
      format.turbo_stream
    end
  end

  private

  def set_entry
    @entry = current_user.entries.find(params[:id])
  end

  def entry_params
    params.require(:entry).permit(:content, :prompt_ref)
  end
end
