class Diary < ApplicationRecord
  belongs_to :user
  
  # ウィークリーレポートとの紐付き（※オプション指定により、レポートが無くても日記は保存可能）
  belongs_to :weekly_report, optional: true

  # （日記が消えたら、関連するデータも一緒に消す設定） 
  has_many :reviews, dependent: :destroy
  has_many :ai_interviews, dependent: :destroy

  # (その他の既存のコード...)
end