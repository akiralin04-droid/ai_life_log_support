class AiReviewGenerationService
  # 引数に campaign_prompt (企業の指示書) を追加します。
  # デフォルト値を nil にしておくことで、普通の日記からの生成時はエラーになりません。
  def initialize(diary_content, additional_info, campaign_prompt: nil)
    @diary_content = diary_content
    @additional_info = additional_info
    @campaign_prompt = campaign_prompt
  end

  def call
    # OpenAIのクライアントを作成
    client = OpenAI::Client.new(access_token: ENV['OPENAI_ACCESS_TOKEN'])

    # キャンペーン(企業プロンプト)の有無で、AIへの基本の命令を切り替えます
    system_instruction = if @campaign_prompt.present?
                           # キャンペーン経由の場合：企業プロンプトに従うように指示
                           "あなたは企業のインタビュアー兼プロのライターです。\n以下の【企業の要望（プロンプト）】に従い、ユーザーの情報を元に魅力的なレビューを作成してください。\n\n【企業の要望】\n#{@campaign_prompt}"
                         else
                           # 通常の生成の場合
                           "あなたはプロのライターです。\n以下の「ユーザーの日記」と、ユーザーが追記した「商品の詳細情報」を組み合わせて、第三者に魅力が伝わる「レビュー記事」を作成してください。"
                         end

    # AIへの最終的な命令文（プロンプト）
    prompt = <<~TEXT
      #{system_instruction}

      【ユーザーの日記（当時の感情）】
      #{@diary_content.presence || "（日記なし）"}

      【商品の詳細情報（スペックや具体的な特徴）】
      #{@additional_info.presence || "（追加情報なし）"}

      出力は以下のJSON形式のみを返してください。余計な会話は不要です。
      {
        "title": "30文字以内の魅力的なタイトル",
        "body": "丁寧な口調で、感情を活かしつつ情報を盛り込んだレビュー本文",
        "emotion_score": "ユーザーの日記や情報から読み取れる『感情の熱量』を、0.0(無感情・ネガティブ)から10.0(最高にポジティブ・熱狂的)の間の小数点第一位までの数値(Float)で出力"
      }
    TEXT

    # APIリクエスト送信
    response = client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages:[{ role: "user", content: prompt }],
        temperature: 0.7,
      }
    )

    # 返ってきた答えを取り出す
    content = response.dig("choices", 0, "message", "content")
    
    # JSON文字列をRubyのハッシュに変換して返す
    JSON.parse(content)
  rescue JSON::ParserError
    # 万が一JSON変換に失敗した場合の保険（emotion_scoreのデフォルト値として5.0を入れています）
    { "title" => "AI自動生成レビュー", "body" => content, "emotion_score" => 5.0 }
  end
end