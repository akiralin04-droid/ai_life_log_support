# 日記機能を管理するコントローラー
class DiariesController < ApplicationController

  # ログインしていないと日記は見れないようにする（ApplicationControllerの設定を引き継ぐ）
  # ▼▼▼ 追加: 編集・更新・削除の前に、権限チェックを行う ▼▼▼
  # これにより、アクションの中で個別にデータ取得を書く必要がなくなります
  before_action :ensure_correct_user, only: [:edit, :update, :destroy]
  # ▲▲▲ 追加ここまで ▲▲▲

  # 日記の一覧画面 (GET /diaries)
  def index
    # ログインしているユーザーの日記だけを、新しい順に取得する
    @diaries = current_user.diaries.order(created_at: :desc)
  end

  # 日記の詳細画面 (GET /diaries/:id)
  def show
    # IDで検索し、「自分のもの」または「公開されているもの」ならOK
    @diary = Diary.find(params[:id])

    unless @diary.user_id == current_user&.id || @diary.is_published?
      redirect_to diaries_path, alert: "この日記は非公開です。"
    end
  end

  # 日記の作成画面 (GET /diaries/new)
  def new
    # 空っぽの日記データを用意する
    @diary = Diary.new
  end

  # 日記の保存処理 (POST /diaries)
  def create
    @diary = current_user.diaries.build(diary_params)

    # 日記を保存（この時点では content は空っぽですが保存します）
    if @diary.save
      # チャットルームを作成（日記のIDを紐づける・目的に「日記作成」を指定）
      @ai_interview = current_user.ai_interviews.create!(diary_id: @diary.id, purpose: :diary_creation)
      
      # OpenAI APIを使って具体的な質問を生成します
      client = OpenAI::Client.new(access_token: ENV['OPENAI_ACCESS_TOKEN'])
      
      prompt = <<~TEXT
        あなたはプロのインタビュアー兼カウンセラーです。ユーザーの以下の「今日の予定」を見て、
        一日の振り返りとして深掘りするための具体的な質問を2〜3個作成してください。
        親しみやすいトーンで、ユーザーが音声で一気に答えやすいように優しく問いかけてください。
        
        【今日の予定】
        #{@diary.schedule}
      TEXT

      begin
        response = client.chat(
          parameters: {
            model: "gpt-3.5-turbo",
            messages:[{ role: "user", content: prompt }],
            temperature: 0.7
          }
        )
        ai_question = response.dig("choices", 0, "message", "content")
      rescue => e
        Rails.logger.error "OpenAI API Error: #{e.message}"
        # エラー時の保険（フェイルセーフ）
        ai_question = "今日もお疲れ様です！スケジュールについて、一番印象に残っている出来事や、心が動いた瞬間について、マイクボタンを使って自由に話してみてください！🎙️"
      end
      
      # AIの第一声として保存
      @ai_interview.ai_messages.create!(role: :assistant, content: ai_question)

      # 作成したチャット画面へリダイレクト
      redirect_to ai_interview_path(@ai_interview), notice: "AIがスケジュールを分析し、質問を作成しました！✨"
      
    else
      render :new, status: :unprocessable_entity
    end
  end

  # 編集画面 (GET /diaries/:id/edit)
  def edit
    # ▼▼▼ 修正: 中身を削除 ▼▼▼
    # ensure_correct_user で @diary がセットされているため、ここは空でOKです
  end

  # 更新処理 (PATCH/PUT /diaries/:id)
  def update
    # ▼▼▼ 修正: データ取得行を削除 ▼▼▼
    # ensure_correct_user で @diary は取得済みです
    
    if @diary.update(diary_params)
      redirect_to @diary, notice: "日記を更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # 日記の削除処理 (DELETE /diaries/:id)
  def destroy
    # ▼▼▼ 修正: データ取得行を削除 ▼▼▼
    # ensure_correct_user で @diary は取得済みです
    
    @diary.destroy
    redirect_to mypage_path, status: :see_other, notice: "日記を削除しました。"
  end

  # ▼▼▼ 追加: みんなの日記一覧アクション ▼▼▼
  def public_index
    # 公開(is_published: true)の日記を、新しい順に取得
    # N+1問題対策で user と review も一緒に取得
    @diaries = Diary.where(is_published: true)
                    .includes(:user, :review)
                    .order(created_at: :desc)
                    .page(params[:page]).per(9) # kaminariがあればページネーション
  end





  private

  # ストロングパラメータ（セキュリティ）
  def diary_params
    params.require(:diary).permit(:content, :is_published, :schedule, :raw_voice_text)
  end

  # ▼▼▼ 追加: 本人確認メソッド ▼▼▼
  def ensure_correct_user
    # find(params[:id]) だと見つからない時にエラー(404)になりますが、
    # find_by(id: params[:id]) だとエラーにならず nil が返ります。
    @diary = current_user.diaries.find_by(id: params[:id])

    # もし見つからなかったら（＝他人の日記、または存在しないID）
    if @diary.nil?
      # エラー画面ではなく、一覧画面へリダイレクトさせます
      redirect_to diaries_path, alert: "権限がありません。"
    end
  end
  # ▲▲▲ 追加ここまで ▲▲▲
end