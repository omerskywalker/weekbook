# frozen_string_literal: true

class TwilioService
  def self.send_sms!(to:, body:)
    return unless twilio_configured?

    client.messages.create(
      from: ENV.fetch('TWILIO_PHONE_NUMBER'),
      to: to,
      body: body
    )
  rescue Twilio::REST::RestError => e
    Rails.logger.error("[TwilioService] SMS failed to #{to}: #{e.message}")
    nil
  end

  def self.twilio_configured?
    ENV['TWILIO_ACCOUNT_SID'].present? &&
      ENV['TWILIO_AUTH_TOKEN'].present? &&
      ENV['TWILIO_PHONE_NUMBER'].present?
  end

  def self.client
    @client ||= Twilio::REST::Client.new(
      ENV.fetch('TWILIO_ACCOUNT_SID'),
      ENV.fetch('TWILIO_AUTH_TOKEN')
    )
  end
  private_class_method :client
end
