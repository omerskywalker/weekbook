# frozen_string_literal: true

class SmsPromptJob < ApplicationJob
  queue_as :low

  def perform
    return unless SmsService.configured?

    User.where(phone_verified: true).find_each do |user|
      next if PromptDispatch.exists?(user: user, date: Date.current)

      dispatch = PromptDispatch.for_today(user)
      next unless dispatch&.prompt_template

      message = build_message(dispatch.prompt_template.body)
      SmsService.send_sms!(to: user.phone, body: message)
    end
  end

  private

  def build_message(prompt_body)
    "#{prompt_body}\n\nReply to save it to your Weekbook. Reply SKIP to skip today."
  end
end
