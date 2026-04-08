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
      dispatch = PromptDispatch.find_by(
        user: user,
        week_start_date: Date.current.beginning_of_week(:monday)
      )
      dispatch&.skip!
      head :ok
    end

    def handle_entry(user, body)
      entry = user.entries.build(
        content: body,
        week_start_date: Date.current.beginning_of_week(:monday)
      )
      entry.save
      head :ok
    end

    def verify_telnyx_signature
      public_key = ENV['TELNYX_PUBLIC_KEY']
      return unless public_key.present?

      sig   = request.headers['telnyx-signature-ed25519'].to_s
      ts    = request.headers['telnyx-timestamp'].to_s
      Telnyx::Webhook.construct_event(request.raw_post, sig, ts, public_key)
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
