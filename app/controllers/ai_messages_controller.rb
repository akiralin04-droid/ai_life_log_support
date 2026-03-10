class AiMessagesController < ApplicationController
  before_action :authenticate_user! if respond_to?(:authenticate_user!)

  def create
    @ai_interview = current_user.ai_interviews.find(params[:ai_interview_id])

    user_message = @ai_interview.ai_messages.build(role: :user, content: params[:content])
    
    if user_message.save
      # 💡 ユーザーの「返信回数」を数える
      user_message_count = @ai_interview.ai_messages.where(role: :user).count

      # 💡 返信が「2回目以上」なら、これ以上質問せずにレビュー生成画面へ自動遷移！
      if user_message_count >= 2
        redirect_to finalize_ai_interview_path(@ai_interview)
        return
      end

      # まだ1回目なら、AIに返事（質問）をもらう
      ai_response_content = fetch_ai_response(@ai_interview)
      
      if ai_response_content.present?
        @ai_interview.ai_messages.create!(role: :assistant, content: ai_response_content)
      end
      
      redirect_to ai_interview_path(@ai_interview)
    else
      redirect_to ai_interview_path(@ai_interview), alert: "メッセージの送信に失敗しました。"
    end
  end

  private

  # =========================================================
  # 🤖 OpenAI APIにリクエストを送る専門のメソッド
  # =========================================================
  def fetch_ai_response(interview)
    client = OpenAI::Client.new(access_token: ENV['OPENAI_ACCESS_TOKEN'])
    
    # 1. AIへの「基本の命令（システムプロンプト）」を作る
    system_prompt = build_system_prompt(interview)
    
    # 2. OpenAIに送るための「会話履歴の配列」を作る
    messages = [{ role: "system", content: system_prompt }]
    
    # 古い順に過去のメッセージをすべて取り出し、配列に追加していく（これが「対話の記憶」になります）
    interview.ai_messages.order(:created_at).each do |msg|
      messages << { role: msg.role, content: msg.content }
    end

    begin
      # 3. OpenAIのAPIを叩く
      response = client.chat(
        parameters: {
          model: "gpt-3.5-turbo",
          messages: messages,
          temperature: 0.7 # 0.7は少し人間らしい自然な会話になる数値です
        }
      )
      # 返ってきた答えのテキスト部分だけを抜き出して返す
      response.dig("choices", 0, "message", "content")
    rescue => e
      Rails.logger.error "OpenAI API Error: #{e.message}"
      "すみません、少し考え込んでしまいました。もう一度送信してみてください！🙏"
    end
  end

  # =========================================================
  # 🧠 状況に応じてAIの性格（プロンプト）を切り替えるメソッド
  # =========================================================
  def build_system_prompt(interview)
    base_prompt = <<~TEXT
      あなたはユーザーの体験や感情を深掘りし、魅力的なレビュー記事を作成するためのプロのインタビュアーです。
      ユーザーとの自然な対話を通して、レビューに必要な情報（良かった点、気になった点、感情の動きなど）を引き出してください。
      一度にたくさんの質問はせず、LINEのように短く、会話のキャッチボールを意識して1〜2個の質問を投げかけてください。
      ハルシネーション（ユーザーが言っていない事実を勝手に捏造すること）は厳禁です。
    TEXT

    if interview.campaign_id.present?
      # キャンペーン経由の場合は、企業のプロンプトを強力に遵守させる！
      campaign_prompt = interview.campaign.ai_prompt
      base_prompt += "\n\nさらに、今回は以下の【企業の要望（プロンプト）】を必ず守ってインタビューを進めてください。\n【企業の要望】\n#{campaign_prompt}"
    elsif interview.diary_id.present?
      # 日記経由の場合は、感情の引き出しに特化させる！
      base_prompt += "\n\n今回はユーザーの『日記』をもとにインタビューしています。日記に書かれた出来事の裏にある「感情の動き」を特に深掘りして、生の声をレビューに活かせるように共感しながら対話してください。"
    end

    base_prompt
  end
end