# frozen_string_literal: true

class AddDateToPromptDispatches < ActiveRecord::Migration[7.2]
  def up
    add_column :prompt_dispatches, :date, :date

    # Backfill existing rows before adding not-null constraint
    execute('UPDATE prompt_dispatches SET date = week_start_date WHERE date IS NULL')

    change_column_null :prompt_dispatches, :date, false

    remove_index :prompt_dispatches, name: 'index_prompt_dispatches_on_user_id_and_week_start_date'
    add_index :prompt_dispatches, %i[user_id date], unique: true
  end

  def down
    remove_index :prompt_dispatches, %i[user_id date]
    add_index :prompt_dispatches, %i[user_id week_start_date],
              unique: true,
              name: 'index_prompt_dispatches_on_user_id_and_week_start_date'
    remove_column :prompt_dispatches, :date
  end
end
