class ReviewsController < ApplicationController
  # ログインしていないとレビュー機能は使えない（ApplicationControllerの設定継承）

  # 1. 一覧画面
  def index
    # 公開されているレビューだけを対象にして、検索オブジェクト(@q)を作ります
    @q = Review.where(is_published: true).ransack(params[:q])
    
    # 画面の見出しがクリックされていない時は、デフォルトで新しい順に並べます
    @q.sorts = 'created_at desc' if @q.sorts.empty?
    
    # 検索結果を1ページ12件ずつに分割して取得します
    @reviews = @q.result(distinct: true).page(params[:page]).per(12)
  end

  # 2. 詳細画面
  def show
    @review = Review.find(params[:id])
  end

  # 3. 新規投稿画面
  def new
    @review = Review.new
  end

  # 4. 投稿保存処理
  def create
    @review = current_user.reviews.build(review_params)
    if @review.save
      redirect_to @review, notice: "レビューを公開しました！"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # 5. 編集画面
  def edit
    @review = current_user.reviews.find(params[:id])
  end

  # 6. 更新処理
  def update
    @review = current_user.reviews.find(params[:id])
    if @review.update(review_params)
      redirect_to @review, notice: "レビューを更新しました！"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 7. 削除処理
  def destroy
    @review = current_user.reviews.find(params[:id])
    @review.destroy
    redirect_to reviews_path, status: :see_other, notice: "レビューを削除しました。"
  end

  # --- ここからAI機能 ---

  # [Step 1] 商品名と詳細を入力する画面
  def select_type
    if params[:diary_id].present?
      @diary = current_user.diaries.find(params[:diary_id])
    else
      @diary = nil
    end
    # ※キャンペーンからの遷移に対応するため、ビュー側で campaign_id を送る準備を後ほどします
  end

  # [Step 2] AI生成を実行して、投稿画面(new)へデータを渡す
  def generate
    additional_info = params[:detail] # フォームから送られてきた詳細情報
    diary_content = ""
    diary_id = nil
    campaign_prompt = nil # 初期値は空にしておく
    campaign_id = params[:campaign_id] # ビューから送られてくる予定のキャンペーンID

    # 日記が選ばれている場合のみ、日記の情報を取得する
    if params[:diary_id].present?
      diary = current_user.diaries.find(params[:diary_id])
      diary_content = diary.content
      diary_id = diary.id
    end

    # キャンペーンIDがある場合、企業プロンプトを取得する
    if campaign_id.present?
      campaign = Campaign.find(campaign_id)
      campaign_prompt = campaign.ai_prompt
    end
    
    # 専門家(Service)に情報を渡す。campaign_prompt も一緒に渡す！
    ai_result = AiReviewGenerationService.new(diary_content, additional_info, campaign_prompt: campaign_prompt).call
    
    # 生成結果を使って、新しいレビューの箱を作る
    @review = Review.new
    @review.title = ai_result["title"]
    @review.body = ai_result["body"]
    @review.emotion_score = ai_result["emotion_score"] # AIが算出した感情スコア！
    @review.diary_id = diary_id
    @review.campaign_id = campaign_id # レビューとキャンペーンを紐付ける
    
    # AIが作った内容が入った状態で、新規投稿画面(new)を表示する
    render :new, status: :unprocessable_entity
  end



  
  private

  # ストロングパラメータ
  def review_params
    params.require(:review).permit(:diary_id, :campaign_id, :title, :body, :rating, :category, :is_published, :emotion_score, :user_emotion_score, :display_emotion_type)
  end

end