# frozen_string_literal: true

class DigestSummarizerJob < ApplicationJob
  queue_as :default

  def perform(user_id, digest_id)
    user = User.find_by(id: user_id)
    return unless user

    digest = WeeklyDigest.find_by(id: digest_id)
    return unless digest

    entries = user.entries.for_week(digest.week_start_date).to_a
    return if entries.empty?

    narrative = OpenaiSummarizer.new(entries).call
    return if narrative.nil?

    digest.content = narrative
    digest.summary_line = narrative.split(/\.\s+|\.$/).first.to_s.truncate(160)
    digest.save

    notify_owner(digest)
  end

  private

  def notify_owner(digest)
    return unless DigestMailer.respond_to?(:digest_ready)

    if digest.user.auto_publish_digest
      digest.publish!
      DigestMailer.digest_auto_published(digest).deliver_later
    else
      DigestMailer.digest_ready(digest).deliver_later
    end
  rescue StandardError => e
    Rails.logger.error("[DigestSummarizerJob] notify_owner failed: #{e.message}")
  end
end
