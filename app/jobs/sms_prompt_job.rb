# frozen_string_literal: true

class SmsPromptJob < ApplicationJob
  queue_as :low

  def perform
    return unless SmsService.configured?

    User.where(phone_verified: true).find_each do |user|
      prompt = PromptDispatch.for_today(user)
      next unless prompt&.prompt_template

      message = build_message(prompt.prompt_template.body)
      SmsService.send_sms!(to: user.phone, body: message)
    end
  end

  private

  def build_message(prompt_body)
    "Weekbook — today's prompt:\n\n#{prompt_body}\n\n" \
      'Reply with your thoughts. Reply SKIP to skip.'
  end
end
