class WeeklyReportsController < ApplicationController
  before_action :authenticate_user! if respond_to?(:authenticate_user!)

  #  レポートの詳細画面 
  def show
    @weekly_report = current_user.weekly_reports.find(params[:id])
    # このレポートに紐づく（使われた）日記を古い順に取得
    @diaries = @weekly_report.diaries.order(created_at: :asc)
  end

  def create
    end_date = Date.today
    start_date = 6.days.ago.to_date

    # 「まだレポートに使われていない（weekly_report_id: nil）」日記だけを取得！
    diaries = current_user.diaries.where(
      created_at: start_date.beginning_of_day..end_date.end_of_day,
      weekly_report_id: nil
    ).order(:created_at)

    if diaries.empty?
      redirect_to mypage_path, alert: "分析できる新しい日記データがありません。日記を書いてから再度お試しください！"
      return
    end

    # テキスト連結
    diary_texts = diaries.map do |d|
      "【#{d.created_at.strftime('%m月%d日')}】\n予定: #{d.schedule}\n本文: #{d.content}"
    end.join("\n\n")

    # AI分析リクエスト
    client = OpenAI::Client.new(access_token: ENV['OPENAI_ACCESS_TOKEN'])
    prompt = <<~TEXT
      あなたはプロのライフコーチ兼アナリストです。
      ユーザーの直近の日記データをもとに、「全体的な傾向とハイライト」「よく頑張った点」「次回に向けた温かいアドバイス」を抽出・整理し、
      300〜400文字程度でモチベーションが上がるレポートを作成してください。
      出力はそのまま画面に表示できる自然な文章とし、箇条書きなどを適宜用いて読みやすくしてください。余計な挨拶は不要です。

      【対象の日記データ】
      #{diary_texts}
    TEXT

    begin
      response = client.chat(
        parameters: { model: "gpt-3.5-turbo", messages: [{ role: "user", content: prompt }], temperature: 0.7 }
      )
      ai_content = response.dig("choices", 0, "message", "content")
    rescue => e
      Rails.logger.error "OpenAI API Error: #{e.message}"
      ai_content = "申し訳ありません。AI分析中にエラーが発生しました。"
    end

    #  トランザクション（安全な連続保存）を使って、レポート作成と日記のマーク付けを同時に行う！
    ActiveRecord::Base.transaction do
      @report = current_user.weekly_reports.create!(
        start_date: start_date,
        end_date: end_date,
        content: ai_content
      )
      
      # 選ばれた日記たちに、今作ったレポートのIDを書き込んで「使用済み」にする
      diaries.update_all(weekly_report_id: @report.id)
    end

    # マイページではなく、今作ったレポートの「詳細画面」へ飛ぶように変更
    redirect_to weekly_report_path(@report), notice: "AIが新しい振り返りレポートを作成しました！✨"
  end

  def destroy
    report = current_user.weekly_reports.find(params[:id])
    report.destroy
    
    # ※モデルの `dependent: :nullify` のおかげで、レポートを消すと
    # 使われていた日記の weekly_report_id は自動で「nil（未使用）」に戻ります！魔法です！
    
    redirect_to mypage_path, notice: "レポートを削除しました。使われていた日記は再び分析可能になりました！"
  end
end