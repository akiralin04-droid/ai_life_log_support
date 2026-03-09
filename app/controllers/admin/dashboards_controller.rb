class Admin::DashboardsController < ApplicationController
  # 管理者以外はこの画面に入れないようにする
  before_action :require_admin

  def index
    # ダッシュボードに表示するため、各データの総数を取得しておく
    @user_count = User.count
    @diary_count = Diary.count
    @review_count = Review.count
    @campaign_count = Campaign.count
    
  end

  private

  # 管理者権限がない場合はトップページに強制送還するメソッド
  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "管理者権限がありません。"
    end
  end
end