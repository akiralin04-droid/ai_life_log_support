class AiReviewGenerationService
  # 引数を2つ（日記、追加詳細）に変更
  def initialize(diary_content, additional_info)
    @diary_content = diary_content
    @additional_info = additional_info
  end

  def call
    # OpenAIのクライアントを作成
    client = OpenAI::Client.new(access_token: ENV['OPENAI_ACCESS_TOKEN'])

    # AIへの命令文（プロンプト）
    prompt = <<~TEXT
      あなたはプロのライターです。
      以下の「ユーザーの日記」と、ユーザーが追記した「商品の詳細情報」を組み合わせて、
      第三者に魅力が伝わる「レビュー記事」を作成してください。

      【日記（当時の感情）】
      #{@diary_content}

      【商品の詳細情報（スペックや具体的な特徴）】
      #{@additional_info}

      出力は以下のJSON形式のみを返してください。余計な会話は不要です。
      {
        "title": "30文字以内の魅力的なタイトル",
        "body": "丁寧な口調で、日記の感情を活かしつつ、詳細情報を盛り込んだ構成されたレビュー本文"
      }
    TEXT

    # APIリクエスト送信
    response = client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [{ role: "user", content: prompt }],
        temperature: 0.7,
      }
    )

    # 返ってきた答えを取り出す
    content = response.dig("choices", 0, "message", "content")
    
    # JSON文字列をRubyのハッシュ（プログラムで扱えるデータ）に変換して返す
    JSON.parse(content)
  rescue JSON::ParserError
    # 万が一JSON変換に失敗した場合（AIが変な形式で返してきた場合）の保険
    { "title" => "AI自動生成レビュー", "body" => content }
  end
end