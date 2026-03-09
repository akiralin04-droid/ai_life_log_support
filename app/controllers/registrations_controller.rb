# ユーザー登録機能を管理するクラス（担当者）
class RegistrationsController < ApplicationController
  # セキュリティの例外設定
  # 通常はログインしていないと追い出されますが、
  # 「新規登録画面(new)」と「登録処理(create)」だけは、ログイン前でもアクセス許可します。
  allow_unauthenticated_access only: %i[ new create ]

  # 登録画面を表示するアクション (GET /registration/new)
  def new
    # 入力フォームで使うために、「空っぽのユーザーデータ」を用意します。
    # Viewで form_with model: @user と書くために必要です。
    @user = User.new
  end

  # 実際に登録処理を行うアクション (POST /registration)
  def create
    # フォームから送られてきたデータ(user_params)を元に、ユーザーの箱を作ります。
    # まだデータベースには保存されていません。
    @user = User.new(user_params)

    # 権限の強制設定
    # フォームから悪意を持って「role=2(管理者)」などのデータが送られてきても無視して、
    # 強制的に「0 (一般ユーザー)」として上書きします。
    @user.role = 0

    # データベースへの保存を試みます
    if @user.save
      # 成功した場合の処理：
      
      # 登録したユーザー情報を使って、そのままログイン状態にします。
      # (ユーザーにわざわざログイン画面で入力させる手間を省くため)
      start_new_session_for @user
      
      # トップページへ画面を移動させ、「完了しました」とメッセージを表示します。
      redirect_to root_path, notice: "アカウント登録が完了しました！"
    else
      # 失敗した場合（名前が空、パスワードが短いなど）の処理：
      
      # もう一度、入力画面(new)を表示します。
      # status: :unprocessable_entity は「処理できませんでした」というエラー信号をブラウザに送る設定です。
      # (Rails 8 / Turbo では、これをつけないとエラーメッセージが表示されません)
      render :new, status: :unprocessable_entity
    end
  end

  private
  # これより下は、このファイルの中でしか呼び出せない「裏方メソッド」です

  # ストロングパラメータ（セキュリティフィルター）
  # フォームから送られてくるデータのうち、許可する項目だけを選別します。
  def user_params
    params.require(:user).permit(
      :name,                  # 名前
      :email_address,         # メールアドレス
      :password,              # パスワード
      :password_confirmation  # パスワード（確認用）
    )
    # ※ここに :role を含めないことで、画面からの権限変更をブロックしています
  end
end