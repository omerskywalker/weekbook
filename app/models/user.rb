# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[google_oauth2 github]

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

  has_many :identities, dependent: :destroy
  has_many :weekly_digests, dependent: :destroy

  has_one_attached :avatar

  def name_for_display
    display_name.presence || username.presence || email.split('@').first
  end

  def following?(other_user)
    following.exists?(other_user.id)
  end

  def self.from_omniauth(auth)
    identity = find_identity(auth)
    return identity.user if identity

    user = find_or_create_user_from_auth(auth)
    user.identities.create!(provider: auth.provider, uid: auth.uid)

    user
  end

  def self.find_identity(auth)
    Identity.find_by(provider: auth.provider, uid: auth.uid)
  end

  def self.find_or_create_user_from_auth(auth)
    email = auth.info.email&.downcase
    raise ArgumentError, 'OAuth provider did not supply an email' if email.blank?

    User.find_by(email: email) || create_user_from_email(email)
  end

  def self.create_user_from_email(email)
    User.create!(
      email: email,
      password: Devise.friendly_token[0, 20]
    )
  end
end
