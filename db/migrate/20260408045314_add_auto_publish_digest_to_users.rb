# frozen_string_literal: true

class AddAutoPublishDigestToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :auto_publish_digest, :boolean, default: false, null: false
  end
end
