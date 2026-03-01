class CreateCampaigns < ActiveRecord::Migration[8.0]
  def change
    create_table :campaigns do |t|
      t.references :user, null: false, foreign_key: true
      t.string :company_name
      t.string :title
      t.text :description
      t.text :ai_prompt
      t.datetime :end_date
      # is_active にデフォルト値 true (有効) を設定
      t.boolean :is_active, default: true, null: false

      t.timestamps
    end
  end
end
