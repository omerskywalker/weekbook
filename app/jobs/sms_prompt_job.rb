# frozen_string_literal: true

class SmsPromptJob < ApplicationJob
  queue_as :low

  def perform
    return unless SmsService.configured?

    week_start = Date.current.beginning_of_week(:monday)

    User.where(phone_verified: true).find_each do |user|
      prompt = PromptDispatch.for_current_week(user)
      next unless prompt&.prompt_template

      message = build_message(week_start, prompt.prompt_template.body)
      SmsService.send_sms!(to: user.phone, body: message)
    end
  end

  private

  def build_message(week_start, prompt_body)
    "Weekbook — Week #{week_start.cweek} prompt:\n\n#{prompt_body}\n\n" \
      'Reply with your thoughts. Reply SKIP to skip.'
  end
end
