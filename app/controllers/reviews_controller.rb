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
      # 日記から遷移してきた場合：元の日記を特定する
      @diary = current_user.diaries.find(params[:diary_id])
    else
      # ダッシュボード等から直接来た場合：日記は使わない
      @diary = nil
    end
  end

  # [Step 2] AI生成を実行して、投稿画面(new)へデータを渡す
  def generate
    additional_info = params[:detail] # フォームから送られてきた詳細情報
    diary_content = ""
    diary_id = nil

    # 日記が選ばれている場合のみ、日記の情報を取得する
    if params[:diary_id].present?
      diary = current_user.diaries.find(params[:diary_id])
      diary_content = diary.content
      diary_id = diary.id
    end
    
    # 専門家(Service)に情報を渡して、レビューを作ってもらう
    # 日記がない場合は diary_content は空文字になりますが、additional_info でAIが文章を作ります
    ai_result = AiReviewGenerationService.new(diary_content, additional_info).call
    
    # 生成結果を使って、新しいレビューの箱を作る
    @review = Review.new
    @review.title = ai_result["title"]
    @review.body = ai_result["body"]
    @review.diary_id = diary_id
    
    # AIが作った内容が入った状態で、新規投稿画面(new)を表示する
    render :new, status: :unprocessable_entity
  end

  private

  # ストロングパラメータ
  def review_params
    # categoryを数値(integer)に変換して受け取るように修正
    params.require(:review).permit(:diary_id, :title, :body, :rating, :category, :is_published).tap do |whitelisted|
      whitelisted[:category] = whitelisted[:category].to_i if whitelisted[:category].present?
    end
  end

end