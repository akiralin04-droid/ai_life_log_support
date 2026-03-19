class CreateAiMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_messages do |t|
      t.references :ai_interview, null: false, foreign_key: true
      t.integer :role, null: false, default: 0
      t.text :content, null: false

      t.timestamps
    end
  end
end