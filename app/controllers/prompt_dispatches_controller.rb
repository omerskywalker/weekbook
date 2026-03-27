# frozen_string_literal: true

class PromptDispatchesController < ApplicationController
  before_action :authenticate_user!

  def skip
    dispatch = current_user.prompt_dispatches.find(params[:id])
    dispatch.skip!
    respond_to do |format|
      format.html { redirect_to entries_path }
      format.turbo_stream { render turbo_stream: turbo_stream.replace('prompt_banner', '') }
    end
  end
end
