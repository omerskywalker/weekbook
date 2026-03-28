# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index? = false
  def show? = false
  def create? = user.present?
  def new? = create?
  def update? = false
  def edit? = update?
  def destroy? = false
end
