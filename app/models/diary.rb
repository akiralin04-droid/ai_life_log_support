class Diary < ApplicationRecord
  belongs_to :user
  has_one :review # 日記から生まれるレビューは1つ

  # Ransack用の検索・並び替え許可リスト
  def self.ransackable_attributes(auth_object = nil)["id", "is_published", "content", "emotion_score", "created_at"]
  end

  # Ransackで「関連するユーザー(user)」の情報も検索して良いと許可します
  def self.ransackable_associations(auth_object = nil)
    ["user"]
  end

end