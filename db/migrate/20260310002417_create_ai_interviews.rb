class CreateAiInterviews < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_interviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :campaign, foreign_key: true
      t.references :diary, foreign_key: true
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end