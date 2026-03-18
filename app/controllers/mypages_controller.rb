class MypagesController < ApplicationController
  before_action :authenticate_user! if respond_to?(:authenticate_user!)

  def show
    @user = current_user

    # カレンダー用のデータ取得（月ごとに切り替え対応！） 
    # URLのパラメータに month=2026-03 のような指定があればその月を、なければ「今月」を基準にする
    @current_month = params[:month] ? Date.parse(params[:month] + "-01") : Date.today.beginning_of_month

    # カレンダーの表示範囲（月初の週の日曜日から、月末の週の土曜日まで）
    @start_date = @current_month.beginning_of_week(:sunday)
    @end_date = @current_month.end_of_month.end_of_week(:sunday)

    # 該当期間の日記をすべて取得
    diaries_in_range = @user.diaries.where(created_at: @start_date.beginning_of_day..@end_date.end_of_day)

    # 件数だけではなく、日記のデータそのものを日付ごとにグループ化して渡す 
    @diaries_by_date = diaries_in_range.group_by { |diary| diary.created_at.to_date }
    
    @diary_count = @user.diaries.count
    @review_count = @user.reviews.count

    # 最新のウィークリーレポートを取得 
    @latest_weekly_report = @user.weekly_reports.order(created_at: :desc).first

    # --- タブ1: 日記履歴（検索付き） ---
    @q_diaries = @user.diaries.ransack(params[:q_diaries], search_key: :q_diaries)
    @diaries = @q_diaries.result.includes(:review).order(created_at: :desc).page(params[:diaries_page]).per(5)

    # --- タブ2: レビュー履歴（検索付き） ---
    @q_reviews = @user.reviews.ransack(params[:q_reviews], search_key: :q_reviews)
    @reviews = @q_reviews.result.includes(:diary).order(created_at: :desc).page(params[:reviews_page]).per(5)

    # --- タブ3: いいね一覧（検索付き） ---
    @q_favorites = @user.favorite_reviews.ransack(params[:q_favorites], search_key: :q_favorites)
    @favorite_reviews = @q_favorites.result.includes(:user).order('favorites.created_at DESC').page(params[:favorites_page]).per(5)

    # タブ4（AIレポート履歴）用のデータ取得
    @weekly_reports = @user.weekly_reports.order(created_at: :desc).page(params[:reports_page]).per(5)
  end
end