class Admin::DiariesController < ApplicationController
  # セキュリティ: 管理者（admin）以外がこの画面にアクセスしようとしたらトップページに弾く
  before_action :require_admin
  
  # コードの重複を避けるため、show, update, destroy アクションが実行される前に、
  # 自動的にURLのID（例: /admin/diaries/5 なら 5）から該当する日記を探し出すメソッドを実行する
  before_action :set_diary, only: %i[show update destroy]

  # 1. 一覧画面の処理
  def index
    # params[:q] には、画面の検索フォームに入力されたキーワードが入ってきます。
    # それをもとに、Ransackがデータベースから検索するための「検索オブジェクト(@q)」を作ります。
    @q = Diary.ransack(params[:q])
    
    # 画面の見出し（並び替えリンク）がクリックされていない時は、デフォルトで「作成日時の新しい順(desc)」に並べる
    @q.sorts = 'created_at desc' if @q.sorts.empty?
    
    # 検索結果を取得し、kaminari(ページ分割機能)を使って、1ページにつき20件ずつ表示するようにする
    @diaries = @q.result(distinct: true).page(params[:page]).per(20)
  end

  # 2. 詳細画面の処理
  def show
    # before_action で @diary がセットされているので、ここに書く処理は空でOKです
  end

  # 3. 更新（公開/非公開の切り替え）の処理
  def update
    # 安全なパラメータ（diary_params）だけを受け取って、データベースを更新(update)する
    if @diary.update(diary_params)
      # 成功したら、詳細画面に戻りつつ、画面上部に緑色のメッセージ(notice)を出す
      redirect_to admin_diary_path(@diary), notice: "日記の公開ステータスを更新しました。"
    else
      # 失敗したら、詳細画面に戻りつつ、赤色のエラーメッセージ(alert)を出す
      redirect_to admin_diary_path(@diary), alert: "更新に失敗しました。"
    end
  end

  # 4. 削除処理
  def destroy
    # データベースからこの日記のデータを完全に消去(destroy)する
    @diary.destroy
    # 削除後は一覧画面に戻る。 status: :see_other は、削除後に安全に画面遷移させるためのRailsの推奨ルール。
    redirect_to admin_diaries_path, notice: "不適切な日記を完全に削除しました。", status: :see_other
  end

  private # ここから下は、このファイルの中でしか使えない「裏方の処理」

  def require_admin
    # current_user（ログイン中の人）が admin?（管理者）でなければ、トップに戻す
    redirect_to root_path, alert: "管理者権限がありません。" unless current_user.admin?
  end

  def set_diary
    # URLのID（params[:id]）を使って、日記のデータベースから1件だけ探してくる
    @diary = Diary.find(params[:id])
  end

  def diary_params
    # 管理者であっても、ハッキング等で勝手に内容(content)などを書き換えられないように、
    # 今回のフォームで変更して良い is_published (公開フラグ) だけを許可(permit)するセキュリティ対策
    params.require(:diary).permit(:is_published)
  end
end