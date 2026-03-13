# frozen_string_literal: true

class Follow < ApplicationRecord
  belongs_to :follower, class_name: 'User'
  belongs_to :followed, class_name: 'User'

  validates :follower_id, uniqueness: { scope: :followed_id }
  validate :cannot_follow_yourself

  private

  def cannot_follow_yourself
    errors.add(:followed_id, 'cannot be the same as follower') if follower_id == followed_id
  end
end
