# frozen_string_literal: true

class CreateWeeklyDigests < ActiveRecord::Migration[7.1]
  def change
    create_table :weekly_digests do |t|
      t.references :user, null: false, foreign_key: true
      t.date :week_start_date, null: false
      t.integer :week_number, null: false
      t.integer :year, null: false
      t.text :content
      t.string :status, null: false, default: 'draft'
      t.string :summary_line

      t.timestamps
    end

    add_index :weekly_digests, %i[user_id week_start_date], unique: true
    add_index :weekly_digests, :status
  end
end
