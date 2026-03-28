# frozen_string_literal: true

class AddPhoneToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :phone, :string, null: true
    add_column :users, :phone_verified, :boolean, null: false, default: false
    add_column :users, :phone_verification_code, :string, null: true
    add_column :users, :phone_verification_sent_at, :datetime, null: true
    add_index :users, :phone, unique: true, where: 'phone IS NOT NULL'
  end
end
