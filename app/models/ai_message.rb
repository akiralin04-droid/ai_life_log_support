class AiMessage < ApplicationRecord
  # このメッセージは、どのインタビューに属しているか
  belongs_to :ai_interview

  # 💡 roleの番号と意味を定義します
  # user: 0 (ユーザーの発言) / assistant: 1 (AIの発言) / system: 2 (裏側の命令用)
  enum :role, { user: 0, assistant: 1, system: 2 }

  # 内容が空っぽのまま保存されないようにするバリデーション
  validates :content, presence: true
end