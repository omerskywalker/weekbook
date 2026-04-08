# frozen_string_literal: true

class PromptTemplate < ApplicationRecord
  CATEGORIES = %w[reflection gratitude challenge highlight].freeze

  has_many :prompt_dispatches, dependent: :destroy

  validates :body, presence: true
  validates :category, inclusion: { in: CATEGORIES }

  scope :active, -> { where(active: true) }
  scope :for_category, ->(cat) { where(category: cat) }

  def self.random_for_week(_week_start = nil)
    active.order('RANDOM()').first
  end
end
