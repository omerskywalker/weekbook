# frozen_string_literal: true

# Telnyx SDK v5+ uses a client-per-request pattern. No global api_key= setter.
# SmsService instantiates Telnyx::Client directly using TELNYX_API_KEY env var.
