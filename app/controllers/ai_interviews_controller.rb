class AiInterviewsController < ApplicationController
  before_action :authenticate_user! if respond_to?(:authenticate_user!)

  def create
    draft_title = params.dig(:review, :title)
    draft_body = params.dig(:review, :body)
    campaign_id = params.dig(:review, :campaign_id) || params[:campaign_id]
    diary_id = params.dig(:review, :diary_id) || params[:diary_id]

    # チャットルームを作成
    @ai_interview = current_user.ai_interviews.create(
      campaign_id: campaign_id,
      diary_id: diary_id
    )

    if draft_title.present? || draft_body.present?
      # 投稿画面から「AIと調整する」ボタンで来た場合の処理
      @ai_interview.ai_messages.create!(role: :user, content: "【現在のタイトル】\n#{draft_title}\n\n【現在の本文】\n#{draft_body}")
      @ai_interview.ai_messages.create!(role: :assistant, content: "下書きを読み込みました！✨\nこの内容をもっと魅力的にするために、どのような点を強調したり修正したいですか？")
    
    elsif diary_id.present?
      # 日記からのルート
      diary = current_user.diaries.find(diary_id)
      
      # 1. ユーザーの最初の発言として、自動的に日記の内容をセットして画面に表示！
      @ai_interview.ai_messages.create!(role: :user, content: "以下の日記をもとにレビューを作りたいです。\n\n【日記の内容】\n#{diary.content}")
      # 2. それに対するAIの第一声
      @ai_interview.ai_messages.create!(role: :assistant, content: "日記の内容を確認しました！✨\nこの日の出来事について、レビューに盛り込みたい「特に感情が動いた瞬間」や「他の人にもおすすめしたいポイント」を一つ教えていただけますか？")

    elsif campaign_id.present?
      # キャンペーンからのルート
      campaign = Campaign.find(campaign_id)
      @ai_interview.ai_messages.create!(role: :assistant, content: "【#{campaign.title}】へのご参加ありがとうございます！✨\n今回のキャンペーンでは企業の要望に沿ってレビューを作成します。\nまずは、体験された率直な感想を自由にお話しください！")
    
    else
      # 通常ルート（入力例を表示）
      first_message = <<~TEXT
        こんにちは！AIレビューアシスタントです✨
        今日はどんなことについてレビューを書きますか？

        （入力例）
        ・昨日観た映画『〇〇』のアクションが最高だった！
        ・駅前のカフェ『△△』のケーキが美味しくて癒やされた。
        ・最近買った『〇〇』というガジェットが便利すぎた！
        
        まずは商品名やタイトルと、簡単な感想を教えてください！
      TEXT
      @ai_interview.ai_messages.create!(role: :assistant, content: first_message)
    end

    redirect_to ai_interview_path(@ai_interview)
  end

  def show
    @ai_interview = current_user.ai_interviews.find(params[:id])
    @messages = @ai_interview.ai_messages.order(:created_at)
  end

  def finalize
    @ai_interview = current_user.ai_interviews.find(params[:id])
    
    conversation_history = @ai_interview.ai_messages.order(:created_at).map do |msg|
      role_name = msg.role == "user" ? "ユーザーの発言" : "AIの質問"
      "【#{role_name}】\n#{msg.content}"
    end.join("\n\n")

    campaign_prompt = @ai_interview.campaign&.ai_prompt
    ai_result = AiReviewGenerationService.new(conversation_history, "", campaign_prompt: campaign_prompt).call

    @review = Review.new(
      title: ai_result["title"],
      body: ai_result["body"],
      emotion_score: ai_result["emotion_score"],
      rating: ai_result["rating"],
      category: ai_result["category"],
      diary_id: @ai_interview.diary_id,
      campaign_id: @ai_interview.campaign_id
    )

    @ai_interview.update(status: :completed)
    render "reviews/new", status: :unprocessable_entity
  end
end