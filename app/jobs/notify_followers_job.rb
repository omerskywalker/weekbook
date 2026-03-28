# frozen_string_literal: true

class NotifyFollowersJob < ApplicationJob
  queue_as :default

  def perform(digest_id)
    digest = WeeklyDigest.find_by(id: digest_id)
    return unless digest&.published?

    digest.user.followers.find_each do |follower|
      DigestMailer.new_digest(follower, digest).deliver_later
    end
  end
end
