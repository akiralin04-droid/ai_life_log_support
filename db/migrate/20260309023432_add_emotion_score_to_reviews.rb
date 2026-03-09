class AddEmotionScoreToReviews < ActiveRecord::Migration[8.0]
  def change
    add_column :reviews, :emotion_score, :float
  end
end
