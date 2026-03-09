class Campaign < ApplicationRecord
  belongs_to :user # 作成者（管理者）
  has_many :reviews

  # Ransack用の設定
  # 1. 検索と並び替えを許可するカラムをすべて列挙します
  def self.ransackable_attributes(auth_object = nil)["is_active", "company_name", "title", "end_date", "created_at"]
  end

  # 2. 検索を許可する関連テーブル（今回は使わないので空にする）
  def self.ransackable_associations(auth_object = nil)[]
  end

end