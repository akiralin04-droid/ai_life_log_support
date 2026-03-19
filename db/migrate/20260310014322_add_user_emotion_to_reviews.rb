class AddUserEmotionToReviews < ActiveRecord::Migration[8.0]
  def change
    # ユーザーが操作するスコア。未設定（操作なし）を許容するためそのまま。
    add_column :reviews, :user_emotion_score, :float
    
    # どちらを公開するか。0=AIのスコア, 1=ユーザーのスコア（初期値は0にする）
    add_column :reviews, :display_emotion_type, :integer, default: 0, null: false
  end
end