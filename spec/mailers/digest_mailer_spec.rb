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

  describe '#digest_ready' do
    let(:owner) { create(:user, display_name: 'Omer') }
    let(:digest) { create(:weekly_digest, user: owner) }
    let(:mail) { described_class.digest_ready(digest) }

    it 'sends to the digest owner' do
      expect(mail.to).to eq([owner.email])
    end

    it 'includes the week number in the subject' do
      expect(mail.subject).to include("Week #{digest.week_number}")
    end

    it 'uses the ready subject line' do
      expect(mail.subject).to include('is ready')
    end

    it 'includes a link to the edit page in the html body' do
      expect(mail.html_part.body.to_s).to include('edit')
    end

    it 'includes a link to the edit page in the text body' do
      expect(mail.text_part.body.to_s).to include('edit')
    end

    it 'mentions reviewing and publishing in the html body' do
      expect(mail.html_part.body.to_s).to include('publish')
    end
  end

  describe '#digest_auto_published' do
    let(:owner) { create(:user, display_name: 'Omer') }
    let(:digest) { create(:weekly_digest, :published, user: owner) }
    let(:mail) { described_class.digest_auto_published(digest) }

    it 'sends to the digest owner' do
      expect(mail.to).to eq([owner.email])
    end

    it 'includes the week number in the subject' do
      expect(mail.subject).to include("Week #{digest.week_number}")
    end

    it 'uses the published subject line' do
      expect(mail.subject).to include('has been published')
    end

    it 'includes a link to the digest in the html body' do
      expect(mail.html_part.body.to_s).to include(weekly_digest_url(digest))
    end

    it 'includes a link to the digest in the text body' do
      expect(mail.text_part.body.to_s).to include(weekly_digest_url(digest))
    end

    it 'mentions auto-publish in the html footer' do
      expect(mail.html_part.body.to_s).to include('auto-publish')
    end
  end
end
