# frozen_string_literal: true

# rubocop:disable Rails/ApplicationController
module Webhooks
  class SmsController < ActionController::Base
    # rubocop:enable Rails/ApplicationController
    skip_forgery_protection

    before_action :verify_telnyx_signature

    def receive
      data = parsed_payload.dig('data', 'payload')
      return head :ok unless data

      from = PhoneUtils.normalize(data.dig('from', 'phone_number').to_s)
      body = data['text'].to_s.strip
      user = User.find_by(phone: from, phone_verified: true)

      return head :ok unless user

      if body.downcase == 'skip'
        handle_skip(user)
      else
        handle_entry(user, body)
      end
    end

    private

    def handle_skip(user)
      dispatch = PromptDispatch.find_by(user: user, date: Date.current)
      dispatch&.skip!
      head :ok
    end

    def handle_entry(user, body)
      dispatch = PromptDispatch.find_by(user: user, date: Date.current)
      entry = user.entries.build(
        content: body,
        week_start_date: Date.current.beginning_of_week(:monday),
        prompt_text: dispatch&.prompt_template&.body
      )
      entry.save
      head :ok
    end

    def verify_telnyx_signature
      public_key = ENV.fetch('TELNYX_PUBLIC_KEY', nil)
      return if public_key.blank?

      sig = request.headers['telnyx-signature-ed25519'].to_s
      ts  = request.headers['telnyx-timestamp'].to_s
      wh  = StandardWebhooks::Webhook.new(public_key)
      wh.verify(request.raw_post, {
                  'webhook-id' => ts,
                  'webhook-timestamp' => ts,
                  'webhook-signature' => sig
                })
    rescue StandardError
      head :forbidden
    end

    def parsed_payload
      @parsed_payload ||= JSON.parse(request.raw_post)
    rescue JSON::ParserError
      {}
    end
  end
end
