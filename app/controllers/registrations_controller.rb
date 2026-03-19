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
    # データベースの激怒（重複エラー）を優しくキャッチする最強の安全網 
    begin
      if @user.save
        start_new_session_for @user
        redirect_to root_path, notice: "アカウント登録が完了しました！"
      else
        render :new, status: :unprocessable_entity
      end
      
    rescue ActiveRecord::RecordNotUnique => e
      # 万が一Railsのチェックをすり抜けて、データベースから「重複してるぞ！」と怒られた場合、
      # 500エラーでシステムを落とさず、画面に赤いエラー文字として優しく表示させます。
      @user.errors.add(:email_address, "はすでに登録されています。別のメールアドレスをお試しください。")
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