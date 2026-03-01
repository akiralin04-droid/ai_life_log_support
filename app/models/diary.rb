class Diary < ApplicationRecord
  belongs_to :user
  has_one :review # 日記から生まれるレビューは1つ
end