# frozen_string_literal: true

# rubocop:disable Rails/ApplicationController
class TwilioWebhooksController < ActionController::Base
  # rubocop:enable Rails/ApplicationController
  skip_forgery_protection

  before_action :verify_twilio_signature

  def inbound
    from = PhoneUtils.normalize(params[:From])
    body = params[:Body].to_s.strip
    user = User.find_by(phone: from, phone_verified: true)

    return render xml: silent_twiml unless user

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
    render xml: twiml_response('Got it — prompt skipped for this week.')
  end

  def handle_entry(user, body)
    entry = user.entries.build(
      content: body,
      week_start_date: Date.current.beginning_of_week(:monday)
    )

    if entry.save
      count = user.entries.for_week(Date.current).count
      render xml: twiml_response(
        "Entry saved! You have #{count} #{'entry'.pluralize(count)} this week."
      )
    else
      render xml: twiml_response("Couldn't save — message must be 5–500 characters.")
    end
  end

  def verify_twilio_signature
    return unless TwilioService.twilio_configured?

    validator = Twilio::Security::RequestValidator.new(ENV.fetch('TWILIO_AUTH_TOKEN', nil))
    url = request.original_url
    valid = validator.validate(url, request.POST, request.headers['X-Twilio-Signature'].to_s)

    head :forbidden unless valid
  end

  def twiml_response(message)
    Twilio::TwiML::MessagingResponse.new do |r|
      r.message(body: message)
    end.to_s
  end

  def silent_twiml
    Twilio::TwiML::MessagingResponse.new.to_s
  end
end
