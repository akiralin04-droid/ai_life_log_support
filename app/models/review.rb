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

  # ビューで使うための「日本語表示名」と「英語キー」のペアを定義します
  def self.category_options
    [
      ['未設定', 'other'],
      ['本', 'book'],
      ['映画', 'movie'],
      ['飲食', 'food'],
      ['ガジェット', 'gadget'],
      ['旅行', 'travel']
    ]
  end
  
   # ▼▼▼ バリデーションを追加 ▼▼▼
  validates :title, presence: true, length: { maximum: 50 }
  validates :body, presence: true
  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :category, presence: true
end