# app/services/ai_summary_service.rb

class AiSummaryService
  # AiSummaryService.new(日記の本文) と呼び出した瞬間に、自動的に実行されるメソッド です。「準備（initialize）」
  def initialize(content)
    # 渡された「日記の本文（content）」を、このクラスの中でずっと使えるように、ポケット（インスタンス変数 @content）にしまっています。
    @content = content
  end

  def call
    # OpenAIのクライアントを作成（APIキーは.envから読み込む）
    client = OpenAI::Client.new(access_token: ENV['OPENAI_ACCESS_TOKEN'])

    # AIへの依頼文（プロンプト）を作成
    response = client.chat(
      parameters: {
        model: "gpt-3.5-turbo", # コストが安くて速いモデル
        messages: [
          { role: "system", content: "あなたは優秀なライフログアシスタントです。ユーザーの日記を読み、共感を示した上で、100文字程度で要約とフィードバックをしてください。" },
          { role: "user", content: @content }
        ],
        temperature: 0.7, # 創造性の度合い（0.7くらいが丁度いい）
      }
    )

    # 返ってきた答えの中から「文章部分」だけを取り出す
    response.dig("choices", 0, "message", "content")
  end
end