# frozen_string_literal: true

class FeedController < ApplicationController
  before_action :authenticate_user!

  PER_PAGE = 10

  def index
    following_ids = current_user.following.pluck(:id)

    @digests = WeeklyDigest
               .published
               .where(user_id: following_ids)
               .includes(:user)
               .recent
               .limit(PER_PAGE)
               .offset(page_offset)

    @total = WeeklyDigest.published.where(user_id: following_ids).count
    @page = current_page
    @has_more = (@page * PER_PAGE) < @total

    @suggestions = suggested_users if following_ids.empty?
  end

  private

  def current_page
    [params[:page].to_i, 1].max
  end

  def page_offset
    (current_page - 1) * PER_PAGE
  end

  def suggested_users
    User.where.not(id: current_user.id)
        .joins(:weekly_digests)
        .where(weekly_digests: { status: 'published' })
        .select('users.*, COUNT(weekly_digests.id) AS digest_count')
        .group('users.id')
        .order('digest_count DESC')
        .limit(5)
  end
end
