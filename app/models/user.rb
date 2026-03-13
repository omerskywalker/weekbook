# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  validates :username,
            uniqueness: true,
            length: { minimum: 3, maximum: 30 },
            format: {
              with: /\A[a-zA-Z0-9_]+\z/,
              message: 'only allows letters, numbers, and underscores'
            },
            allow_blank: true

  validates :display_name, length: { maximum: 50 }, allow_blank: true
  validates :bio, length: { maximum: 280 }, allow_blank: true

  def name_for_display
    display_name.presence || username.presence || email.split('@').first
  end

  has_many :active_follows,
           class_name: 'Follow',
           foreign_key: :follower_id,
           dependent: :destroy,
           inverse_of: :follower

  has_many :passive_follows,
           class_name: 'Follow',
           foreign_key: :followed_id,
           dependent: :destroy,
           inverse_of: :followed

  has_many :following, through: :active_follows, source: :followed
  has_many :followers, through: :passive_follows, source: :follower

  has_one_attached :avatar

  def following?(other_user)
    following.exists?(other_user.id)
  end
end
