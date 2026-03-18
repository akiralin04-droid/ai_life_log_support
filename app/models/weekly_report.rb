class WeeklyReport < ApplicationRecord
  belongs_to :user

  #  1つのレポートは、複数の日記を元に作られる 
  # (dependent: :nullify は、レポートを削除した時に、日記自体は消さずに「使用済みマーク」だけを外す魔法の設定です)
  has_many :diaries, dependent: :nullify

end
