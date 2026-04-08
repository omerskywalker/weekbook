# frozen_string_literal: true

class AddPromptTextToEntries < ActiveRecord::Migration[7.2]
  def change
    add_column :entries, :prompt_text, :string
  end
end
