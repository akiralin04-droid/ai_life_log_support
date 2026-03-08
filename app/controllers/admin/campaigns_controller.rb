class Admin::CampaignsController < ApplicationController
  # すべてのアクションの前に「管理者かどうか」をチェックする
  before_action :require_admin
  # idを使って特定のキャンペーンを探す処理を、各アクションの前に実行する
  before_action :set_campaign, only: %i[show edit update destroy]

  # 1. 一覧画面
  def index
    # 作成日時の新しい順でキャンペーンを取得
    @campaigns = Campaign.order(created_at: :desc)
  end

  # 2. 詳細画面
  def show
  end

  # 3. 新規作成画面
  def new
    @campaign = Campaign.new
  end

  # 4. 作成処理
  def create
    # current_user（ログイン中の管理者）と紐付けて新しいキャンペーンを作成
    @campaign = current_user.campaigns.build(campaign_params)
    
    if @campaign.save
      redirect_to admin_campaign_path(@campaign), notice: "キャンペーンを作成しました！"
    else
      # 失敗時は新規作成画面に戻す
      render :new, status: :unprocessable_entity
    end
  end

  # 5. 編集画面
  def edit
  end

  # 6. 更新処理
  def update
    if @campaign.update(campaign_params)
      redirect_to admin_campaign_path(@campaign), notice: "キャンペーンを更新しました！"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 7. 削除処理
  def destroy
    @campaign.destroy
    redirect_to admin_campaigns_path, notice: "キャンペーンを削除しました。", status: :see_other
  end

  private

  # 管理者でない場合は、トップページに強制送還するメソッド
  def require_admin
    unless current_user.admin?
      redirect_to root_path, alert: "管理者権限がありません。"
    end
  end

  # URLの :id から対象のキャンペーンを探す
  def set_campaign
    @campaign = Campaign.find(params[:id])
  end

  # フォームから送られてくる安全なデータだけを許可する（ストロングパラメータ）
  def campaign_params
    params.require(:campaign).permit(:company_name, :title, :description, :ai_prompt, :end_date, :is_active)
  end
end