# frozen_string_literal: true

class SmsService
  def self.send_sms!(to:, body:)
    return unless configured?

    client = Telnyx::Client.new(api_key: ENV.fetch('TELNYX_API_KEY'))
    client.messages.send_long_code(
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
