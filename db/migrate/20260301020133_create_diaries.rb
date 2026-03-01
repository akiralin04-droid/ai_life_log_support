class CreateDiaries < ActiveRecord::Migration[8.0]
  def change
    create_table :diaries do |t|
      t.references :user, null: false, foreign_key: true
      t.text :content
      t.text :ai_response
      t.float :emotion_score
      # is_published にデフォルト値 false (非公開) を設定
      t.boolean :is_published, default: false, null: false

      t.timestamps
    end
  end
end
