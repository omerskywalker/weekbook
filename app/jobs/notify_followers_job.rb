# frozen_string_literal: true

class NotifyFollowersJob < ApplicationJob
  queue_as :low

  def perform(digest_id)
    # TODO: notify followers when a digest is published
    Rails.logger.info("[NotifyFollowersJob] digest_id=#{digest_id}")
  end
end
