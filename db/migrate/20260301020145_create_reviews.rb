class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      # ★ここを変更！ null: true (空っぽでもOK) にする
      t.references :diary, null: true, foreign_key: true
      t.references :campaign, null: true, foreign_key: true
      t.string :title
      t.text :body
      # ★デフォルト値 0 を設定
      t.integer :rating, default: 0
      t.integer :category, default: 0
      # ★デフォルト値 true (公開) を設定
      t.boolean :is_published, default: true, null: false

      t.timestamps
    end
  end
end
