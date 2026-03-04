class Review < ApplicationRecord
  belongs_to :user
  belongs_to :diary, optional: true    # 任意（なくてもOK）
  belongs_to :campaign, optional: true # 任意（なくてもOK）
  
  has_many :comments, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :review_tags, dependent: :destroy
  has_many :tags, through: :review_tags

  # ★★★ カテゴリの番号と名前の対応表 ★★★
  # 0:未設定, 1:本, 2:映画, 3:飲食, 4:ガジェット, 5:旅行 ...など
  enum :category, { other: 0, book: 1, movie: 2, food: 3, gadget: 4, travel: 5 }
end