class AiMessagesController < ApplicationController
  before_action :authenticate_user! if respond_to?(:authenticate_user!)

  def create
    @ai_interview = current_user.ai_interviews.find(params[:ai_interview_id])

    user_message = @ai_interview.ai_messages.build(role: :user, content: params[:content])
    
    if user_message.save
      user_message_count = @ai_interview.ai_messages.where(role: :user).count

      # 日記モードかどうかの判定
      is_diary_mode = !@ai_interview.review_creation?

      # 💡 日記モードなら「1回」、レビューモードなら「2回」で自動遷移！
      if (is_diary_mode && user_message_count >= 1) || (!is_diary_mode && user_message_count >= 2)
        redirect_to finalize_ai_interview_path(@ai_interview)
        return
      end

      # まだ規定回数に達していなければ、AIに返事（質問）をもらう
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
    # ベースの性格を「自己成長を促すライフコーチ」に変更 
    base_prompt = <<~TEXT
      あなたはユーザーの体験や感情を優しく深掘りし、自己成長を促す優秀なライフコーチ兼インタビュアーです。
      ユーザーとの自然な対話を通して、出来事の裏にある「気づき」や「改善点」を引き出してください。
      一度にたくさんの質問はせず、LINEのように短く、共感を示しながら1つだけ質問を投げかけてください。
      ハルシネーション（ユーザーが言っていない事実を勝手に捏造すること）は厳禁です。
    TEXT

    if interview.campaign_id.present?
      # 【レビュー作成（キャンペーン）モード】
      campaign_prompt = interview.campaign.ai_prompt
      base_prompt += "\n\n今回は以下の【企業の要望（プロンプト）】を必ず守り、レビュー作成のためのインタビューを進めてください。\n【企業の要望】\n#{campaign_prompt}"
      
    elsif interview.diary_id.present?
      if interview.diary.content.present?
        # 【レビュー作成（日記から）モード】（すでに日記本文が存在する場合）
        base_prompt += "\n\n今回はユーザーの『完成した日記』をもとに、魅力的なレビューを作成するためのインタビューをしています。他の人におすすめしたいポイントを引き出してください。"
      else
        # 日記作成時の深掘りも、コーチングのトーンに変更 
        base_prompt += "\n\n今回は、箇条書きの『本日のスケジュール』をもとに、ユーザーの一日の振り返りをサポートし、「未来に活かせる気づき」や「反省点」を引き出すためのコーチングインタビューです。ユーザーの気持ちに寄り添い、自己成長に繋がる深掘りをしてください。"
      end
    end

    base_prompt
  end


end