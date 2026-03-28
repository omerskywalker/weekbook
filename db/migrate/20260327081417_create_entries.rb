# frozen_string_literal: true

class CreateEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :entries do |t|
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.string :prompt_ref
      t.date :week_start_date, null: false

      t.timestamps
    end
    add_index :entries, %i[user_id week_start_date]
  end
end
