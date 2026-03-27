# frozen_string_literal: true

class Entry < ApplicationRecord
  belongs_to :user

  validates :content, presence: true, length: { minimum: 5, maximum: 500 }
  validates :week_start_date, presence: true

  before_validation :set_week_start_date, on: :create

  scope :for_week, ->(date) { where(week_start_date: date.beginning_of_week(:monday)) }
  scope :recent, -> { order(created_at: :desc) }

  def this_week?
    week_start_date == Date.current.beginning_of_week(:monday)
  end

  private

  def set_week_start_date
    self.week_start_date ||= Date.current.beginning_of_week(:monday)
  end
end
