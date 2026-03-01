class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  has_many :diaries, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :campaigns, dependent: :destroy # 管理者として作成したもの
  has_many :comments, dependent: :destroy
  has_many :favorites, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  
  # 画像設定
  has_one_attached :profile_image
end