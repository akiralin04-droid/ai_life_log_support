class MypagesController < ApplicationController
  before_action :authenticate_user! if respond_to?(:authenticate_user!)

  def show
    @user = current_user
    
    @diary_count = @user.diaries.count
    @review_count = @user.reviews.count

    # --- タブ1: 日記履歴（検索付き） ---
    @q_diaries = @user.diaries.ransack(params[:q_diaries], search_key: :q_diaries)
    @diaries = @q_diaries.result.includes(:review).order(created_at: :desc).page(params[:diaries_page]).per(5)

    # --- タブ2: レビュー履歴（検索付き） ---
    @q_reviews = @user.reviews.ransack(params[:q_reviews], search_key: :q_reviews)
    @reviews = @q_reviews.result.includes(:diary).order(created_at: :desc).page(params[:reviews_page]).per(5)

    # --- タブ3: いいね一覧（検索付き） ---
    @q_favorites = @user.favorite_reviews.ransack(params[:q_favorites], search_key: :q_favorites)
    @favorite_reviews = @q_favorites.result.includes(:user).order('favorites.created_at DESC').page(params[:favorites_page]).per(5)
  end
end