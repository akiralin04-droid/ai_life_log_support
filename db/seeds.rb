puts "🚀 発表デモ用データの作成を開始します..."

# ==========================================
# 1. デモ用メインユーザーの準備（管理者とゲスト）
# ==========================================
admin_user = User.find_by(role: :admin) || User.create!(name: "管理者", email_address: "admin@example.com", password: "password", password_confirmation: "password", role: :admin, onboarding_completed: true, introduction: "AI Life Log Supportのシステム管理者です。日々の運用状況をモニタリングしています。")

guest_user = User.find_or_create_by!(email_address: "guest@example.com") do |u|
  u.name = "ゲストユーザー"
  u.password = "password"
  u.password_confirmation = "password"
  u.role = :general
  u.onboarding_completed = true
  u.introduction = "ポートフォリオ発表会へようこそ！このアカウントでアプリの全機能をお試しいただけます。"
end

# 何度シードを実行してもデータが重複しないよう、管理者とゲストの過去データを一旦リセット
puts "🧹 既存のデモ履歴をクリーンアップ中..."
[admin_user, guest_user].each do |user|
  user.ai_interviews.destroy_all
  user.reviews.destroy_all
  user.diaries.destroy_all
  user.weekly_reports.destroy_all
end

# ==========================================
# 2. 企業のキャンペーン作成
# ==========================================
campaign1 = Campaign.find_or_create_by!(title: "極上の「ととのい」体験レビュー") do |c|
  c.user = admin_user; c.company_name = "星野リゾート"; c.description = "サウナを利用した際のリアルな感情を募集します！"; c.ai_prompt = "一番ととのった瞬間の感情を深掘りしてください。"; c.end_date = 1.month.from_now; c.is_active = true
end

campaign2 = Campaign.find_or_create_by!(title: "新作映画感想キャンペーン") do |c|
  c.user = admin_user; c.company_name = "TOHOシネマズ"; c.description = "新作映画の感想を大募集！"; c.ai_prompt = "映画で一番印象に残ったシーンの感情を深掘りしてください。"; c.end_date = 1.month.from_now; c.is_active = true
end

# ==========================================
# 3. 【管理者】過去10週間分（約70日分）の大量データを作成
# ==========================================
puts "📊 管理者のマイページ用履歴データ（10週間分）を作成中..."

10.times do |i|
  # i=0が今週、i=9が10週間前
  weeks_ago = 9 - i
  start_date = weeks_ago.weeks.ago.beginning_of_week(:sunday).to_date
  end_date = weeks_ago.weeks.ago.end_of_week(:sunday).to_date
  
  # 💡 10個のウィークリー分析レポートを作成
  report = WeeklyReport.create!(
    user: admin_user,
    start_date: start_date,
    end_date: end_date,
    content: "【AIウィークリー分析レポート：#{start_date.strftime('%m/%d')}〜#{end_date.strftime('%m/%d')}】\n今週は新しい技術の学習や、PF作成において大きな進捗がありました。感情スコアの平均も高く、充実した1週間だったと言えます。特に#{start_date.strftime('%A')}の活動はモチベーションが高く保てていました。このペースを維持して来週も頑張りましょう！",
    created_at: end_date.to_time + 20.hours
  )

  # 💡 各週ごとに3つの日記とレビューを作成（合計30個）
  3.times do |j|
    target_date = start_date + j.days * 2 # 日、火、木に作成
    
    diary = Diary.create!(
      user: admin_user,
      schedule: "午前：プログラミング学習\n午後：機能実装\n夜：リフレッシュ",
      content: "【1日の流れ】\n・午前中にアルゴリズムの学習\n・午後はAI連携機能の実装\n・夜はゆっくりお風呂\n\n【良かったこと】\n・エラーを自分で解決できた\n・実装スピードが上がってきた\n\n【改善点】\n・少し夜更かししてしまった\n\n【気づき】\n・こまめに休憩を取る方が最終的な効率は良い",
      raw_voice_text: "今日は一日プログラミングに集中しました。途中でエラーにハマったけど、なんとか解決できて達成感がすごいです。",
      ai_response: "素晴らしい集中力と問題解決能力ですね！エラーを乗り越えた達成感は、エンジニアとしての大きな成長の証です。夜はしっかり休んで、明日も良い一日にしましょう！",
      is_published: true,
      weekly_report_id: report.id, # レポートに紐付け
      created_at: target_date.to_time + 21.hours
    )
    
    Review.create!(
      user: admin_user,
      diary: diary,
      title: "エラー解決から学ぶプログラミングの面白さ",
      body: "今日は開発中に難しいバグに直面しましたが、公式ドキュメントを読み込んで解決することができました。最初はイライラしていましたが、原因が分かった瞬間の喜びは格別です。この達成感があるからエンジニアは辞められません。",
      rating: rand(3..5),
      emotion_score: rand(3.5..5.0).round(1),
      user_emotion_score: rand(3.0..5.0).round(1),
      category: 1,
      is_published: true,
      created_at: diary.created_at + 1.hour
    )
  end
end

# ==========================================
# 4. 【ゲスト】面接官・講師がログインした時用のデータ
# ==========================================
puts "👤 ゲストユーザー用の体験データを作成中..."

# デモ用：今日の朝に書いた日記
demo_diary = Diary.create!(
  user: guest_user,
  schedule: "朝：ポートフォリオの最終確認\n昼：成果発表会！",
  content: "【1日の流れ】\n・朝早く起きてプレゼンの練習\n・昼からいよいよ成果発表会本番！\n\n【良かったこと】\n・自分のこだわり（音声入力やPWA）をしっかり伝えられそう！\n\n【改善点】\n・少し緊張している\n\n【気づき】\n・開発の苦労を乗り越えた分、自信を持って発表できる",
  raw_voice_text: "いよいよ今日は成果発表会です！この1ヶ月間、一生懸命作ったアプリをみんなに見てもらうのが楽しみです。緊張するけど頑張ります！",
  ai_response: "いよいよ成果発表会ですね！これまでの努力の結晶を披露する最高の舞台です。緊張は真剣に取り組んできた証拠。自信を持って、あなたのこだわりを全力で伝えてきてください！応援しています✨",
  is_published: true,
  created_at: Time.current - 5.hours
)

Review.create!(
  user: guest_user,
  diary: demo_diary,
  title: "いざ、成果発表会へ！",
  body: "約1ヶ月間、UXと最新技術にこだわって開発してきた『AI Life Log Support』。Web Speech APIやRails 8のPWA対応など、挑戦の連続でしたが、最高のプロダクトに仕上がりました。本日のデモ発表で、このアプリの魅力を余すことなくお伝えします！",
  rating: 5,
  emotion_score: 4.9,
  user_emotion_score: 5.0,
  category: 0,
  is_published: true,
  created_at: Time.current - 4.hours
)

puts "🎉 すべてのデモ用データの流し込みが完了しました！"