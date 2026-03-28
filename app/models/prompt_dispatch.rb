# frozen_string_literal: true

class PromptDispatch < ApplicationRecord
  belongs_to :user
  belongs_to :prompt_template

  STATUSES = %w[pending responded skipped].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :dispatched_at, presence: true
  validates :week_start_date, presence: true
  validates :user_id,
            uniqueness: { scope: :week_start_date, message: 'already has a prompt for this week' }

  scope :for_week, ->(date) { where(week_start_date: date.beginning_of_week(:monday)) }
  scope :pending, -> { where(status: 'pending') }

  def self.for_current_week(user)
    monday = Date.current.beginning_of_week(:monday)
    find_or_create_for_week(user, monday)
  end

  def self.find_or_create_for_week(user, monday)
    existing = find_by(user: user, week_start_date: monday)
    return existing if existing

    template = PromptTemplate.random_for_week
    return nil unless template

    create!(
      user: user,
      prompt_template: template,
      dispatched_at: Time.current,
      week_start_date: monday
    )
  end

  def pending?
    status == 'pending'
  end

  def respond!
    update!(status: 'responded')
  end

  def skip!
    update!(status: 'skipped')
  end
end
