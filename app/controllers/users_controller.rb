class UsersController < ApplicationController
  # ログインチェックが必要ならコメントアウトを外す
  # before_action :require_login 
  
  # 編集・更新・表示の前に、IDからユーザーを特定する
  before_action :set_user, only: [:show, :edit, :update]
  
  # 本人以外が編集画面にアクセスできないようにするガード
  before_action :ensure_correct_user, only: [:edit, :update, :destroy]

  def index
    # 今回は使用しませんが、管理画面などで使う可能性があります
    @users = User.all
  end

  def show
    # マイページとは別に、他の人から見たプロフィール画面として使えます
  end

  def edit
    # @user は before_action でセットされています
  end

  def update
    # ストロングパラメータを使って更新を試みる
    if @user.update(user_params)
      # 更新成功時はマイページへリダイレクトし、メッセージを表示
      redirect_to mypage_path, notice: "プロフィールを更新しました。"
    else
      # 失敗時は編集画面を再表示（エラーメッセージが出るようにします）
      flash.now[:alert] = "更新に失敗しました。入力内容を確認してください。"
      render :edit, status: :unprocessable_entity
    end
  end

   # アカウント削除処理
  def destroy
    # @user は before_action :set_user で取得済み想定
    @user.destroy
    reset_session # ログイン情報を破棄
    redirect_to root_path, status: :see_other, notice: "退会しました。ご利用ありがとうございました。"
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  # Strong Parameters: 編集を許可する項目を指定
  def user_params
    params.require(:user).permit(:name, :introduction, :profile_image, :custom_format)
  end

  # 本人確認（URLのIDとログイン中のIDが違う場合は弾く）
  def ensure_correct_user
    # current_user が定義されている前提
    if @user.id != current_user.id
      redirect_to mypage_path, alert: "権限がありません。"
    end
  end

end