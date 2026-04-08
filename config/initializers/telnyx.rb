# frozen_string_literal: true

# Telnyx 5.x uses a client-based API — the global api_key= setter was removed.
# SmsService instantiates Telnyx::Client directly with the API key from env.
