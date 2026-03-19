# 日記機能を管理するコントローラー
class DiariesController < ApplicationController

  # ログインしていないと日記は見れないようにする（ApplicationControllerの設定を引き継ぐ）
  # 編集・更新・削除の前に、権限チェックを行う 
  # これにより、アクションの中で個別にデータ取得を書く必要がなくなります
  before_action :ensure_correct_user, only: [:edit, :update, :destroy]

  # 日記の一覧画面 (GET /diaries)
  def index
    # ログインしているユーザーの日記だけを、新しい順に取得する
    # 【N+1対策】一覧で「レビュー済みか」等の判定を行うため、review を一緒に取得！
    @diaries = current_user.diaries.includes(:review).order(created_at: :desc)
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
      
      #  声でそのまま日記化ルート（チャットをスキップ） 
      if @diary.raw_voice_text.present?
        # ユーザーの発言として保存
        @ai_interview.ai_messages.create!(role: :user, content: @diary.raw_voice_text)
        
        # AiInterviewsControllerのfinalizeへ強制遷移させ、一発で日記本文と分析を生成させる！
        redirect_to finalize_ai_interview_path(@ai_interview), notice: "音声データを送信しました。AIが日記を生成しています...✨"
        return
      end

      # OpenAI APIを使って具体的な質問を生成します
      client = OpenAI::Client.new(access_token: ENV['OPENAI_ACCESS_TOKEN'])
      
      # ▼▼▼ 未来に活かせる気づき・反省を引き出すコーチングプロンプト ▼▼▼
      prompt = <<~TEXT
        あなたはユーザーの自己成長をサポートする優秀なライフコーチです。
        ユーザーが入力した以下の「今日の予定」を読み込み、今日一日を深く振り返り、
        未来に活かせる「気づき」や「反省点」を引き出すための質問を【1つだけ】作成してください。

        【厳守事項】
        1. 予定の中から具体的なキーワードを拾い、それに絡めて質問すること。
        2. 単なる感想ではなく、「何がうまくいったか」「もっとどうすれば良かったか」「そこから何を学んだか」を考えさせるような、優しくも鋭い問いかけにすること。
        3. ユーザーがマイクに向かって音声で答えやすいよう、親しみやすいトーンにすること。
        4. 出力は質問の文章のみ（挨拶などは不要）としてください。
        
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

  # 本人確認メソッド 
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

end