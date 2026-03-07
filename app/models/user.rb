# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :username,
            uniqueness: true,
            length: { minimum: 3, maximum: 30 },
            format: {
              with: /\A[a-zA-Z0-9_]+\z/,
              message: "only allows letters, numbers, and underscores"
            },
            allow_blank: true

  validates :display_name, length: { maximum: 50 }, allow_blank: true
  validates :bio, length: { maximum: 280 }, allow_blank: true

  def name_for_display
    display_name.presence || username.presence || email.split("@").first
  end
end
