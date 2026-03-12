require 'openai' # Gemを確実に読み込むために追加

class AiSummaryService
  def initialize(content)
    @content = content
  end

  def call
    # APIキーが設定されていない場合のガード
    return "APIキーが設定されていません" unless ENV['OPENAI_ACCESS_TOKEN']

    begin
      # OpenAIのクライアントを作成
      client = OpenAI::Client.new(access_token: ENV['OPENAI_ACCESS_TOKEN'])

      # AIへの依頼文（プロンプト）
      response = client.chat(
        parameters: {
          model: "gpt-3.5-turbo",
          messages:[
            { role: "system", content: "あなたは優秀なライフログアナリストです。ユーザーの日記を読み、第三者目線で「今日の良かった点」と「明日に向けた簡単なアドバイス」を整理し、200文字程度でフィードバックしてください。箇条書きなどを用いて見やすく出力してください。" },
            { role: "user", content: @content }
          ],
          temperature: 0.7,
        }
      )

      # 結果を取り出す
      response.dig("choices", 0, "message", "content")

    rescue => e
      # エラーが起きた場合はログに残し、ユーザーにはエラーメッセージを返す
      Rails.logger.error "OpenAI Error: #{e.message}"
      "申し訳ありません。AIとの通信中にエラーが発生しました。"
    end
  end
end