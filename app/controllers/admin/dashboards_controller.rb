class Admin::DashboardsController < ApplicationController
  # 管理者以外はこの画面に入れないようにする
  before_action :require_admin

  def index
    # ダッシュボードに表示するため、各データの総数を取得しておく
    @user_count = User.count
    @diary_count = Diary.count
    @review_count = Review.count
    @campaign_count = Campaign.count

    # 感情スコアのギャップが大きいレビュー（AI評価 vs 自己評価）上位5件
    # MySQLのABS関数で絶対値（差分）を計算し、ギャップが大きい順に取得
    @gap_reviews = Review.where.not(emotion_score: nil)
                         .where.not(user_emotion_score: nil)
                         .order(Arel.sql('ABS(emotion_score - user_emotion_score) DESC'))
                         .limit(5)
                         .includes(:user, :diary)

    # アクティブなキャンペーン（直近の5件）と、それに紐づく利用状況
    @active_campaigns = Campaign.where(is_active: true)
                                .includes(:reviews, :ai_interviews)
                                .order(created_at: :desc)
                                .limit(5)

    # 最新のAI対話履歴（AIインタビュー）上位5件
    @recent_ai_interviews = AiInterview.includes(:user, :diary, :campaign)
                                       .order(created_at: :desc)
                                       .limit(5)
    
  end

  private

  # 管理者権限がない場合はトップページに強制送還するメソッド
  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "管理者権限がありません。"
    end
  end
end