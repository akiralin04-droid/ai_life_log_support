class AiInterviewsController < ApplicationController
  before_action :authenticate_user! if respond_to?(:authenticate_user!)

  def create
    draft_title = params.dig(:review, :title)
    draft_body = params.dig(:review, :body)
    campaign_id = params.dig(:review, :campaign_id) || params[:campaign_id]
    diary_id = params.dig(:review, :diary_id) || params[:diary_id]
    
    # 送られてきた目的（なければデフォルトでレビュー作成）
    purpose = params[:purpose] || "review_creation"

    # レビューの対象を受け取る
    review_target = params[:review_target]

    # チャットルームを作成
    @ai_interview = current_user.ai_interviews.create!(
      campaign_id: campaign_id,
      diary_id: diary_id,
      purpose: purpose
    )

    if @ai_interview.diary_refinement?
      # 【推敲（修正）モード】のルート
      diary = current_user.diaries.find(diary_id)
      refinement_request = params[:refinement_request]

      client = OpenAI::Client.new(access_token: ENV['OPENAI_ACCESS_TOKEN'])
      # コーチとして推敲の質問をさせる 
      prompt = <<~TEXT
        あなたはユーザーの自己成長をサポートするライフコーチです。ユーザーが作成した「現在の日記」と、「修正したいポイント（要望）」を読み、
        要望を深掘りするための的確な質問を1つだけ作成してください。

        【重要】
        現在の日記のどの項目（良かったこと、改善点、気づき等）についての修正なのかを文脈から判断し、未来に活かせるような前向きな問いかけにしてください。

        【現在の日記】
        #{diary.content}

        【ユーザーの修正要望】
        #{refinement_request}
      TEXT

      begin
        response = client.chat(
          parameters: { model: "gpt-3.5-turbo", messages:[{ role: "user", content: prompt }], temperature: 0.7 }
        )
        ai_question = response.dig("choices", 0, "message", "content")
      rescue => e
        Rails.logger.error "OpenAI API Error: #{e.message}"
        ai_question = "要望を確認しました！修正をより良くするために、マイクボタンを使ってもう少し詳しく教えていただけますか？🎙️"
      end
      
      @ai_interview.ai_messages.create!(role: :assistant, content: ai_question)
      redirect_to ai_interview_path(@ai_interview), notice: "AIが要望を読み込みました！チャットで推敲しましょう✨"
      return

    elsif draft_title.present? || draft_body.present?
      # 投稿画面から「AIと調整する」ボタンで来た場合の処理
      @ai_interview.ai_messages.create!(role: :user, content: "【現在のタイトル】\n#{draft_title}\n\n【現在の本文】\n#{draft_body}")
      @ai_interview.ai_messages.create!(role: :assistant, content: "下書きを読み込みました！✨\nこの内容をもっと魅力的にするために、どのような点を強調したり修正したいですか？")
    
    elsif diary_id.present? && @ai_interview.review_creation?
      # 日記からレビューを作るルートで、対象をAIに教える
      diary = current_user.diaries.find(diary_id)
      
      if review_target.present?
        @ai_interview.ai_messages.create!(role: :user, content: "今日の日記の中から、「#{review_target}」についてレビューを作りたいです。\n\n【日記の内容】\n#{diary.content}")
        @ai_interview.ai_messages.create!(role: :assistant, content: "「#{review_target}」についてのレビューですね！✨\n日記の内容を確認しました。この「#{review_target}」について、特に他の人におすすめしたいポイントや、一番魅力に感じた部分を一つ教えていただけますか？")
      else
        @ai_interview.ai_messages.create!(role: :user, content: "以下の日記をもとにレビューを作りたいです。\n\n【日記の内容】\n#{diary.content}")
        @ai_interview.ai_messages.create!(role: :assistant, content: "日記の内容を確認しました！✨\nこの日の出来事について、レビューに盛り込みたい「特に感情が動いた瞬間」や「他の人にもおすすめしたいポイント」を一つ教えていただけますか？")
      end

    elsif campaign_id.present?
      # キャンペーンからのルート
      campaign = Campaign.find(campaign_id)
      @ai_interview.ai_messages.create!(role: :assistant, content: "【#{campaign.title}】へのご参加ありがとうございます！✨\n今回のキャンペーンでは企業の要望に沿ってレビューを作成します。\nまずは、体験された率直な感想を自由にお話しください！")
    
    else
      # 通常ルート
      first_message = "こんにちは！AIレビューアシスタントです✨\nまずは商品名やタイトルと、簡単な感想を教えてください！"
      @ai_interview.ai_messages.create!(role: :assistant, content: first_message)
    end

    redirect_to ai_interview_path(@ai_interview)
  end

  def show
    @ai_interview = current_user.ai_interviews.find(params[:id])
    @messages = @ai_interview.ai_messages.order(:created_at)
  end

  def finalize
    @ai_interview = current_user.ai_interviews.find(params[:id])
    
    # 会話履歴をテキストにまとめる
    conversation_history = @ai_interview.ai_messages.order(:created_at).map do |msg|
      role_name = msg.role == "user" ? "ユーザーの発言" : "AIの質問"
      "【#{role_name}】\n#{msg.content}"
    end.join("\n\n")

    # 日記モードかどうかの判定
    is_diary_mode = !@ai_interview.review_creation?

    if is_diary_mode
      # =========================================================
      # 📝 日記モード：AIによる日記の自動執筆処理
      # =========================================================
      client = OpenAI::Client.new(access_token: ENV['OPENAI_ACCESS_TOKEN'])
      
      # 「訂正の反映」と「メタ発言の禁止」を厳命する！
      correction_instruction = <<~INSTRUCTION
        ※重要なお願い（厳守）※
        1. ユーザーの「会話履歴」は音声入力の生データであるため、誤認識や文法の乱れが含まれています。自然な日本語に補正してください。
        2. ユーザーの発言の中に「〇〇じゃなくて〜」といったAIの勘違いに対する訂正が含まれる場合、その訂正を正確に汲み取り、間違った文脈を修正してください。
        3. 「修正したいという要望もあり」や「ゲームの話題を追加します」といった、推敲作業そのものに関する発言（メタ発言）は、日記本文には絶対に含めないでください。あくまで「ユーザーが体験した出来事のみ」として自然な日記にしてください。
      INSTRUCTION

      # AIに「絶対のルール」として認識させる枠を作る 
      if @ai_interview.user.custom_format.present?
        # ユーザーが独自の設定をしている場合
        user_instruction = <<~FORMAT
          【ユーザーからの絶対的な出力指示（Custom Instructions）】
          以下の指示に従って出力形式や口調を決定してください。これは最も優先されるルールです。
          #{@ai_interview.user.custom_format}
        FORMAT
      else
        # 独自設定がない場合のデフォルトフォーマット
        user_instruction = <<~FORMAT
          【指定フォーマット】
          以下の4つの見出しを必ず使い、箇条書きで簡潔にまとめること。
          1日の流れ
          ・
          良かったこと
          ・
          改善点
          ・
          気づき
          ・
        FORMAT
      end

      prompt = if @ai_interview.diary_refinement?
                 # ▼▼▼ 修正：推敲時も性格・口調を完全に同期 ▼▼▼
                 <<~TEXT
                   あなたはユーザーの専属アシスタントです。
                   以下の「現在の日記」に対して、「推敲の会話履歴」で新しく語られたエピソードや気づきを組み込み、内容をアップデートしてください。
                   ※アシスタントの「性格・口調・出力フォーマット」は、以下の【ユーザーからの絶対的な出力指示】に完全に依存・同期させてください。

                   【厳守事項】
                   1. ユーザーからの絶対的な出力指示（または指定フォーマット）に完全に乗り移り、その口調と形式を維持して出力すること。これを最優先とします。
                   2. 会話履歴の内容を適切に反映させること。
                   3. ユーザーが話していない事実（ハルシネーション）は絶対に作らないこと。
                   4. 挨拶や「承知しました」などの前置きは一切含めず、本文のみを出力すること。

                   #{user_instruction}

                   #{correction_instruction}

                   【現在の日記】
                   #{@ai_interview.diary.content}

                   【推敲の会話履歴（追加の修正要望と回答）】
                   #{conversation_history}
                 TEXT
               else
                 # ▼▼▼ 修正：新規作成時も性格・口調を完全に同期 ▼▼▼
                 <<~TEXT
                   あなたはユーザーの専属アシスタントです。
                   提供された「本日の予定」と「振り返りの生データ」を読み解き、1日を振り返る日記を出力してください。
                   ※アシスタントの「性格・口調・出力フォーマット」は、以下の【ユーザーからの絶対的な出力指示】に完全に依存・同期させてください。

                   【厳守事項】
                   1. ユーザーからの絶対的な出力指示（または指定フォーマット）に完全に乗り移り、その口調と形式で出力すること。これを最優先とします。
                   2. ユーザーが話していない事実（ハルシネーション）は絶対に作らないこと。
                   3. 挨拶や「出力します」などの前置き・後書きは一切含めず、本文のみを出力すること。

                   #{user_instruction}

                   #{correction_instruction}

                   【本日の予定（未入力の場合は無視）】
                   #{@ai_interview.diary.schedule}

                   【振り返りの生データ】
                   #{conversation_history}
                 TEXT
               end

      begin
        response = client.chat(
          parameters: { model: "gpt-3.5-turbo", messages:[{ role: "user", content: prompt }], temperature: 0.7 }
        )
        ai_diary_content = response.dig("choices", 0, "message", "content")
      rescue => e
        Rails.logger.error "OpenAI API Error: #{e.message}"
        ai_diary_content = "（AIでの日記生成に失敗しました。以下の生データをもとに編集してください）\n\n#{conversation_history}"
      end

      # 生データを「上書き」ではなく、仕切り線を入れて「追記」する処理に変更！
      if @ai_interview.diary_refinement?
        # 推敲（2回目以降）の場合：既存のデータの末尾に追加する
        separator = "\n\n================================\n【追加の推敲データ】\n================================\n"
        new_raw_voice_text = @ai_interview.diary.raw_voice_text.to_s + separator + conversation_history
      else
        # 新規作成（1回目）の場合：タイトルをつけて保存する
        new_raw_voice_text = "【1回目の音声データ】\n" + conversation_history
      end

      # 日記が完成したので、ここでAI分析レポートも作って一緒に保存する！
      # AI分析でエラーが起きても、日記本文と音声データだけは確実に保存するフェイルセーフ！
      begin
        ai_response = AiSummaryService.new(ai_diary_content).call
      rescue => e
        Rails.logger.error "AiSummaryService Error: #{e.message}"
        ai_response = "（現在AIが混雑しており、分析レポートの生成にタイムアウトしました。後ほど編集画面からお試しください）"
      end

      @ai_interview.diary.update!(
        content: ai_diary_content,
        raw_voice_text: new_raw_voice_text,
        ai_response: ai_response
      )

      @ai_interview.update!(status: :completed)

      redirect_to diary_path(@ai_interview.diary), notice: "AIが音声をもとに日記を完璧に修正しました！✨"
      
    else
      # =========================================================
      # 📝 レビューモード：既存のレビュー生成処理（そのまま）
      # =========================================================
      campaign_prompt = @ai_interview.campaign&.ai_prompt

      # AIの生成がタイムアウトしても、ユーザーの「会話履歴（音声データ）」を本文に直接入れて絶対に守る！
      begin
        ai_result = AiReviewGenerationService.new(conversation_history, "", campaign_prompt: campaign_prompt).call
      rescue => e
        Rails.logger.error "AiReviewGenerationService Error: #{e.message}"
        ai_result = {
          "title" => "【AI生成エラー】手動で編集してください",
          "body" => "（※AIの処理がタイムアウトしました。以下の生データをもとにレビューを作成してください）\n\n#{conversation_history}",
          "emotion_score" => 0.0,
          "rating" => 3,
          "category" => 0
        }
      end

      @review = Review.new(
        title: ai_result["title"],
        body: ai_result["body"],
        emotion_score: ai_result["emotion_score"],
        rating: ai_result["rating"],
        category: ai_result["category"],
        diary_id: @ai_interview.diary_id,
        campaign_id: @ai_interview.campaign_id
      )

      @ai_interview.update(status: :completed)

       # エラー時であっても入力画面は表示され、ユーザーは会話履歴からコピペして手動でレビューを完成できる
      render "reviews/new", status: :unprocessable_entity
    end
    
  end

end