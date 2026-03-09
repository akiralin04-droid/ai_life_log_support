class Review < ApplicationRecord
  belongs_to :user
  belongs_to :diary, optional: true    # 任意（なくてもOK）
  belongs_to :campaign, optional: true # 任意（なくてもOK）
  
  has_many :comments, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :review_tags, dependent: :destroy
  has_many :tags, through: :review_tags

  # ★★★ カテゴリの番号と名前の対応表 ★★★
  # 既存の0〜4はそのまま活かし、5以降を新しいビジョンに合わせて再構築しました！
  # 過去のデータがエラーにならないように、数字は被らないように割り当てています。
  enum :category, { 
    other: 0, 
    book: 1, 
    movie: 2, 
    food: 3, 
    gadget: 4, 
    place: 5,           # 変更: お店・施設（旧travelを含める）
    beauty_health: 6,   # 追加: 美容・健康（モノ）
    lifestyle: 7,       # 追加: 生活雑貨・インテリア
    service: 8,         # 追加: サービス・体験
    game: 9             # 追加: ゲーム・アプリ
  }

  # ビューで使うための「日本語表示名」と「英語キー」のペアを定義します
  # この配列の順番が、画面のプルダウンメニューの順番になります。
  def self.category_options
    [
      ['未設定', 'other'],['お店・施設', 'place'],          # Google連携を見据えて上に配置！
      ['飲食・グルメ', 'food'],['本・マンガ', 'book'],
      ['映画・アニメ', 'movie'],['ゲーム・アプリ', 'game'],
      ['ガジェット・家電', 'gadget'],
      ['美容・健康', 'beauty_health'],
      ['生活雑貨・インテリア', 'lifestyle'],
      ['サービス・体験', 'service']
    ]
  end
  
  # バリデーション
  validates :title, presence: true, length: { maximum: 50 }
  validates :body, presence: true
  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :category, presence: true

  # 検索と並び替えを許可するカラム
  def self.ransackable_attributes(auth_object = nil)["id", "is_published", "title", "body", "category", "rating", "emotion_score", "created_at"]
  end

  # 関連テーブルの検索許可
  def self.ransackable_associations(auth_object = nil)
    ["user", "diary", "campaign", "tags"]
  end
end