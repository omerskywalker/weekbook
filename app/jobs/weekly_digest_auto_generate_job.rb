# frozen_string_literal: true

class WeeklyDigestAutoGenerateJob < ApplicationJob
  queue_as :default

  def perform
    week_start = Date.current.beginning_of_week(:monday)

    User.find_each do |user|
      entries = user.entries.for_week(Date.current)
      next if entries.empty?

      digest = WeeklyDigest.find_or_initialize_by(user: user, week_start_date: week_start) do |d|
        d.week_number = week_start.cweek
        d.year        = week_start.cwyear
      end

      next if digest.published? || digest.archived?

      digest.save! if digest.new_record?
      DigestSummarizerJob.perform_later(user.id, digest.id)
    end
  end
end
