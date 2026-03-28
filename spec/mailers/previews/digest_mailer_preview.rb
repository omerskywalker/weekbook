# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/digest_mailer_mailer
class DigestMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/digest_mailer_mailer/new_digest
  delegate :new_digest, to: :DigestMailer
end
