class MypagesController < ApplicationController
  # ログイン必須（実装に合わせてコメントアウトを外してください）
  # before_action :require_login 

  def show
    @user = current_user
    
    # 統計情報
    @diary_count = @user.diaries.count
    # 自分の日記についたレビューの総数
    @review_count = Review.joins(:diary).where(diaries: { user_id: @user.id }).count

    # --- タブ表示用データの取得 ---

    # Tab 1: 日記履歴 (全ての日記)
    # パラメータ名: diaries_page
    @diaries = @user.diaries.includes(:review)
                    .order(created_at: :desc)
                    .page(params[:diaries_page]).per(5)

    # Tab 2: レビュー履歴 (自分の日記へのAI分析結果)
    # パラメータ名: reviews_page
    @reviews = Review.joins(:diary).where(diaries: { user_id: @user.id })
                     .includes(:diary)
                     .order(created_at: :desc)
                     .page(params[:reviews_page]).per(5)

    # Tab 3: いいね一覧 (自分がいいねしたレビュー)
    # パラメータ名: favorites_page
    # ※ER図にFavoritesテーブルがある前提です
    @favorite_reviews = @user.favorite_reviews
                             .includes(:diary, :user) # N+1対策
                             .order('favorites.created_at DESC')
                             .page(params[:favorites_page]).per(5)
  end
end