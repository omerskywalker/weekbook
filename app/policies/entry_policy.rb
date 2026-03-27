# frozen_string_literal: true

class EntryPolicy < ApplicationPolicy
  def index? = user.present?
  def new? = user.present?
  def create? = user.present?
  def destroy? = record.user_id == user&.id
end
