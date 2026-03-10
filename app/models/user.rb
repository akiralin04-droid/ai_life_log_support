class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  has_many :diaries, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :campaigns, dependent: :destroy # 管理者として作成したもの
  has_many :comments, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :favorite_reviews, through: :favorites, source: :review
  has_many :ai_interviews, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  
  # 画像設定
  has_one_attached :profile_image

  # （0: 一般ユーザー、1: 管理者）
  enum :role, { general: 0, admin: 1 }

  # 👇 ここからRansack用の設定（差し替え）
  # 1. 検索と並び替えを許可するカラムをすべて列挙します
  def self.ransackable_attributes(auth_object = nil)["id", "role", "is_active", "name", "email_address", "created_at"]
  end

  # 2. 検索を許可する関連テーブル（今回は使わないので空にする）
  def self.ransackable_associations(auth_object = nil)
    []
  end

end