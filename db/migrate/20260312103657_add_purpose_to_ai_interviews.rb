class AddPurposeToAiInterviews < ActiveRecord::Migration[8.0]
  def change
    # 💡 default: 0 をつけることで、過去に作られたチャットデータがエラーになるのを防ぎます
    add_column :ai_interviews, :purpose, :integer, default: 0, null: false
  end
end