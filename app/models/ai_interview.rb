class AiInterview < ApplicationRecord
  belongs_to :user
  
  # 💡 optional: true をつけることで、Rails側でも「ここは空っぽ(nil)でもOKだよ」と許可します
  belongs_to :campaign, optional: true
  belongs_to :diary, optional: true

  # 1つのインタビューは、たくさんのメッセージ(発言)を持つ（親が消えたら子も消える）
  has_many :ai_messages, dependent: :destroy

  # 💡 statusの番号と意味を定義します
  # in_progress: 0 (進行中) / completed: 1 (完了・レビュー生成済み)
  enum :status, { in_progress: 0, completed: 1 }
end