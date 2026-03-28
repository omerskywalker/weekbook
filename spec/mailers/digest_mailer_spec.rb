# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DigestMailer do
  describe '#new_digest' do
    let(:author) { create(:user, display_name: 'Omer') }
    let(:follower) { create(:user) }
    let(:digest) do
      create(:weekly_digest,
             user: author,
             status: 'published',
             summary_line: 'A great week of building.')
    end
    let(:mail) { described_class.new_digest(follower, digest) }

    it 'sends to the follower' do
      expect(mail.to).to eq([follower.email])
    end

    it 'includes the author name in the subject' do
      expect(mail.subject).to include(author.name_for_display)
    end

    it 'includes the week number in the subject' do
      expect(mail.subject).to include("Week #{digest.week_number}")
    end

    it 'includes the summary line in the body' do
      expect(mail.html_part.body.to_s).to include('A great week of building.')
    end

    it 'includes a link to the digest' do
      expect(mail.html_part.body.to_s).to include(weekly_digest_url(digest))
    end
  end
end
