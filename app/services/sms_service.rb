# frozen_string_literal: true

class SmsService
  def self.send_sms!(to:, body:)
    return unless configured?

    Telnyx::Message.create(
      from: ENV.fetch('TELNYX_PHONE_NUMBER'),
      to: to,
      text: body
    )
  rescue StandardError => e
    Rails.logger.error("[SmsService] SMS failed to #{to}: #{e.message}")
    nil
  end

  def self.configured?
    ENV['TELNYX_API_KEY'].present? && ENV['TELNYX_PHONE_NUMBER'].present?
  end
end
