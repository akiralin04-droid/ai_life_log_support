class Campaign < ApplicationRecord
  belongs_to :user # 作成者（管理者）
  has_many :reviews
end