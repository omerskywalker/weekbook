# frozen_string_literal: true

class CreatePromptDispatches < ActiveRecord::Migration[7.1]
  def change
    create_table :prompt_dispatches do |t|
      t.references :user, null: false, foreign_key: true
      t.references :prompt_template, null: false, foreign_key: true
      t.datetime :dispatched_at, null: false
      t.string :status, null: false, default: 'pending'
      t.date :week_start_date, null: false

      t.timestamps
    end
    add_index :prompt_dispatches, %i[user_id week_start_date], unique: true
  end
end
