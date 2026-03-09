class Admin::UsersController < ApplicationController
  before_action :require_admin

  def index
    @q = User.ransack(params[:q])
    # ソート指定がない時だけ、デフォルトで新しい順にする
    @q.sorts = 'created_at desc' if @q.sorts.empty?
    @users = @q.result(distinct: true).page(params[:page]).per(20)
  end

  def show
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      redirect_to admin_user_path(@user), notice: "ユーザーの権限を更新しました。"
    else
      redirect_to admin_user_path(@user), alert: "更新に失敗しました。"
    end
  end

  def destroy
    @user = User.find(params[:id])
    
    # 自分自身（ログイン中の管理者）は削除できないようにする安全対策
    if @user == current_user
      redirect_to admin_user_path(@user), alert: "自分自身のアカウントは削除できません。"
    else
      @user.destroy
      redirect_to admin_users_path, notice: "ユーザーのアカウントを完全に削除しました。", status: :see_other
    end
  end

  private

  # 管理者以外を弾くセキュリティの鍵
  def require_admin
    redirect_to root_path, alert: "管理者権限がありません。" unless current_user.admin?
  end

  def user_params
    # 管理者画面からは、role（権限）と is_active（有効/停止）を変更できるように許可する
    params.require(:user).permit(:role, :is_active)
  end
end