# frozen_string_literal: true

class DigestSummarizerJob < ApplicationJob
  queue_as :default

  def perform(user_id, week_start_date_str)
    user = User.find_by(id: user_id)
    return unless user

    week_start = Date.parse(week_start_date_str)
    entries = user.entries.for_week(week_start).to_a
    return if entries.empty?

    # Find the prompt dispatch for the week (if any) and get its prompt_template body
    dispatch = PromptDispatch.for_week(week_start).find_by(user: user)
    prompt_text = dispatch&.prompt_template&.body

    narrative = OpenaiSummarizer.new(entries, prompt_text: prompt_text).call
    return if narrative.nil?

    digest = WeeklyDigest.for_week(week_start)
    digest.user = user
    digest.content = narrative
    digest.summary_line = narrative.split(/\.\s+|\.$/).first.to_s.truncate(160)
    digest.save
  end
end
