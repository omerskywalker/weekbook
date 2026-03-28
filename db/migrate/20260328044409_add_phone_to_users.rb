# frozen_string_literal: true

class AddPhoneToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :phone, :string
    add_column :users, :phone_verified, :boolean, default: false, null: false
    add_column :users, :phone_verification_code, :string
    add_column :users, :phone_verification_sent_at, :datetime
  end
end
