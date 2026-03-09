class Favorite < ApplicationRecord
  belongs_to :user
  belongs_to :review

  # 1人のユーザーが同じレビューを重複していいねできないようにする
  validates :user_id, uniqueness: { scope: :review_id }
  
end