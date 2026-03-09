class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create guest_login ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "少し時間をおいて再度お試しください。" }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      # 凍結されているかどうかのチェック
      unless user.is_active?
        redirect_to new_session_path, alert: "このアカウントは現在利用停止されています。お問い合わせください。"
        return
      end
      
      # ログイン成功時の分岐
      start_new_session_for user
      
      if user.admin?
        # 管理者ならダッシュボードへ
        redirect_to admin_path, notice: "管理者としてログインしました。"
      else
        # 一般ユーザーなら本来行きたかったページ（またはTOP）へ
        redirect_to after_authentication_url, notice: "ログインしました。"
      end
    else
      redirect_to new_session_path, alert: "メールアドレスかパスワードが間違っています。"
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, notice: "ログアウトしました。"
  end

  def guest_login
    user = User.find_or_create_by!(email_address: 'guest@example.com') do |user|
      user.password = SecureRandom.urlsafe_base64
      user.name = "ゲストユーザー"
    end
    
    start_new_session_for user
    redirect_to root_path, notice: 'ゲストユーザーとしてログインしました。'
  end
end