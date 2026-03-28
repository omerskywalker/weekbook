# frozen_string_literal: true

class WeeklyDigest < ApplicationRecord
  belongs_to :user

  STATUSES = %w[draft published archived].freeze

  validates :week_start_date, presence: true
  validates :week_number, presence: true, inclusion: { in: 1..53 }
  validates :year, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :summary_line, length: { maximum: 160 }, allow_blank: true
  validates :user_id,
            uniqueness: { scope: :week_start_date, message: 'already has a digest for this week' }

  scope :published, -> { where(status: 'published') }
  scope :draft, -> { where(status: 'draft') }
  scope :recent, -> { order(week_start_date: :desc) }

  def self.for_week(date)
    monday = date.beginning_of_week(:monday)
    find_or_initialize_by(
      week_start_date: monday,
      week_number: monday.cweek,
      year: monday.cwyear
    )
  end

  def self.current_week(user)
    for_week(Date.current).tap { |d| d.user = user }
  end

  def week_end_date
    week_start_date + 6.days
  end

  def week_range_label
    start_label = week_start_date.strftime('%b %-d')
    end_label   = week_end_date.strftime('%b %-d')
    "#{start_label} – #{end_label}"
  end

  def published?
    status == 'published'
  end

  def draft?
    status == 'draft'
  end

  def publish!
    update!(status: 'published')
  end

  def unpublish!
    update!(status: 'draft')
  end
end
