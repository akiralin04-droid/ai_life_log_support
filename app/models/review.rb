class Review < ApplicationRecord
  belongs_to :user
  belongs_to :diary, optional: true    # 任意（なくてもOK）
  belongs_to :campaign, optional: true # 任意（なくてもOK）
  
  has_many :comments, dependent: :destroy
  has_many :favorites, dependent: :destroy
  has_many :review_tags, dependent: :destroy
  has_many :tags, through: :review_tags
end