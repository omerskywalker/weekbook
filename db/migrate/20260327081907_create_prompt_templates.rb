class CreatePromptTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :prompt_templates do |t|
      t.text :body, null: false
      t.string :category, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :prompt_templates, [:category, :active]
  end
end
