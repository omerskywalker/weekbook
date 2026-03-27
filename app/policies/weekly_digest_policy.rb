# frozen_string_literal: true

class WeeklyDigestPolicy < ApplicationPolicy
  def index? = user.present?
  def show? = record.published? || record.user_id == user&.id
  def new? = user.present?
  def create? = user.present?
  def edit? = record.user_id == user&.id
  def update? = record.user_id == user&.id
  def publish? = record.user_id == user&.id
  def unpublish? = record.user_id == user&.id
  def generate? = record.user_id == user&.id
end
