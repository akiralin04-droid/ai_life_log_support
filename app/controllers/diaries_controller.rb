# 日記機能を管理するコントローラー
class DiariesController < ApplicationController
  # ログインしていないと日記は見れないようにする（ApplicationControllerの設定を引き継ぐ）
  # なので、allow_unauthenticated_access は書きません

  # 日記の一覧画面 (GET /diaries)
  def index
    # ログインしているユーザーの日記だけを、新しい順に取得する
    # (他人の日記は見えないようにするため、current_user.diaries を使う)
    @diaries = current_user.diaries.order(created_at: :desc)
  end

  # 日記の詳細画面 (GET /diaries/:id)
  def show
    # URLのIDから日記を探す
    # 他人の日記をURL直打ちで見られないよう、ここでも current_user.diaries から探す
    @diary = current_user.diaries.find(params[:id])
  end

  # 日記の作成画面 (GET /diaries/new)
  def new
    # 空っぽの日記データを用意する
    @diary = Diary.new
  end

  # 日記の保存処理 (POST /diaries)
  def create
    # フォームから送られてきたデータを使って、日記のインスタンスを作る
    # current_user.diaries.build とすることで、自動的に user_id がセットされる
    @diary = current_user.diaries.build(diary_params)

    # ▼▼▼ AI機能の実装 ▼▼▼
    # AIサービスを呼び出して、要約を生成してもらう
    # （日記の中身が空っぽじゃない時だけ実行する）
    if @diary.content.present?
      # 専門家(AiSummaryService)に日記を渡して、結果をもらう
      ai_response = AiSummaryService.new(@diary.content).call
      
      # 返ってきた結果を、日記データの ai_response カラムに入れる
      @diary.ai_response = ai_response
    end

    # データベースへの保存を試みる
    if @diary.save
      # ★ここに後で「AI要約ロジック」を追加します！
      
      # ▼▼▼ 修正箇所: 成功時のメッセージを変更 ▼▼▼
      # 保存に成功したら、作成した日記の詳細画面(@diary)へ飛ばします
      redirect_to @diary, notice: "日記を保存しました！（AI分析は準備中です）"
    else
      # 失敗したら（空っぽなど）、作成画面をもう一度表示する
      # status: :unprocessable_entity は、バリデーションエラー時のHTTPステータスコード(422)です
      render :new, status: :unprocessable_entity
    end
  end

  # 日記の削除処理 (DELETE /diaries/:id)
  def destroy
    # 削除対象の日記を探す
    @diary = current_user.diaries.find(params[:id])
    
    # 削除を実行する
    @diary.destroy
    
    # ▼▼▼ 修正箇所: 戻り先をマイページへ変更 ▼▼▼
    # 一覧画面(diaries_path)ではなく、マイページ(mypage_path)に戻るように変更しました
    # status: :see_other (303) は、DELETEリクエスト後のリダイレクトで推奨されるステータスコードです
    redirect_to mypage_path, status: :see_other, notice: "日記を削除しました。"
  end

  private

  # ストロングパラメータ（セキュリティ）
  def diary_params
    # 日記の本文と、公開/非公開の設定だけを許可する
    # フォームから送られてくる :diary というキーの中の :content と :is_published だけを受け取る
    params.require(:diary).permit(:content, :is_published)
  end
end