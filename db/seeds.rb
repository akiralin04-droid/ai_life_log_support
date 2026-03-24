# db/seeds.rb

puts "発表デモ用データの作成を開始します...✨"

# ==========================================
# 1. 架空の企業キャンペーンを作成
# ==========================================
# 管理者ユーザーを取得（いなければ作成）
admin_user = User.find_by(role: :admin) || User.create!(name: "管理者", email_address: "admin@example.com", password: "password", password_confirmation: "password", role: :admin, onboarding_completed: true)

campaign1 = Campaign.find_or_create_by!(title: "極上の「ととのい」体験レビュー") do |c|
  c.user = admin_user
  c.company_name = "星野リゾート"
  c.description = "サウナ施設を利用した際の、心と体の変化や「ととのった」瞬間のリアルな感情を募集します！"
  c.ai_prompt = "ユーザーがサウナでどのようにリラックスしたか、温度や水風呂の感想、そして一番「ととのった」と感じた瞬間の感情を深掘りしてください。"
  c.end_date = 1.month.from_now
  c.is_active = true
end

campaign2 = Campaign.find_or_create_by!(title: "新作映画『AIの夜明け』感想キャンペーン") do |c|
  c.user = admin_user
  c.company_name = "TOHOシネマズ"
  c.description = "話題の新作映画の感想を大募集！ラストシーンの衝撃や、心を打たれたセリフを教えてください。"
  c.ai_prompt = "映画のどのシーンが一番印象に残ったか、登場人物の誰に一番共感したか、そして見終わった後の率直な気持ちをインタビューしてください。"
  c.end_date = 1.month.from_now
  c.is_active = true
end

# ==========================================
# 2. デモ用ユーザーと、ギャップのあるレビューを作成
# ==========================================
# 【ユーザー1】
user1 = User.find_or_create_by!(email_address: "demo1@example.com") do |u|
  u.name = "サウナ好きの田中"
  u.password = "password"
  u.password_confirmation = "password"
  u.onboarding_completed = true
  u.introduction = "週末のサウナ巡りが趣味です。いろんな施設の水風呂を記録しています。"
end

# 日記1（サウナ）
diary1 = Diary.find_or_create_by!(raw_voice_text: "【1回目の音声データ】\n今日は仕事でクタクタだったので、夜にサウナに行ってきました。水風呂が冷たくて最高だったんですが、人が多くてちょっと落ち着かなかったかな。でもまあ、体はスッキリしました。") do |d|
  d.user = user1
  d.schedule = "夜：近所のサウナへ"
  d.content = "【1日の流れ】\n・夜に近所のサウナへ\n\n【良かったこと】\n・仕事の疲れを癒やせた\n・水風呂が冷たくて最高だった\n\n【改善点】\n・人が多くて少し落ち着かなかった\n\n【気づき】\n・混雑する時間を避ける工夫が必要かもしれない"
  d.ai_response = "お疲れ様でした！人が多くて少し残念でしたが、水風呂でスッキリできたようで何よりです。次回はぜひ、人が少ない時間を狙って究極のリラックスを体験してみてくださいね！"
  d.is_published = true
  d.created_at = 2.days.ago
end

# レビュー1：AIは「疲れが吹き飛んだ」などの言葉から高評価。しかしユーザーは「人が多くて落ち着かなかった」ため自己評価は低め（ギャップ大！）
Review.find_or_create_by!(title: "水風呂は最高！でも混雑が…") do |r|
  r.user = user1
  r.diary = diary1
  r.campaign = campaign1
  r.body = "仕事終わりにサウナへ。水風呂の温度管理は完璧で、一気に疲れが吹き飛びました。ただ、金曜の夜ということもあり人が多く、ととのいスペースが空いていなかったのが少し残念。施設自体は素晴らしいので、次は平日の昼間に行ってみたいです。"
  r.rating = 3
  r.emotion_score = 4.8      # AIのスコアは高い
  r.user_emotion_score = 2.5 # ユーザーの自己評価は低い
  r.is_published = true
  r.created_at = 2.days.ago
end
AiInterview.find_or_create_by!(diary: diary1) { |i| i.user = user1; i.campaign = campaign1; i.purpose = :review_creation; i.status = :completed; i.created_at = 2.days.ago }


# 【ユーザー2】
user2 = User.find_or_create_by!(email_address: "demo2@example.com") do |u|
  u.name = "映画マニアの佐藤"
  u.password = "password"
  u.password_confirmation = "password"
  u.onboarding_completed = true
  u.introduction = "年間100本映画を見ます。特にSF映画が大好きです。"
end

# 日記2（映画）
diary2 = Diary.find_or_create_by!(raw_voice_text: "【1回目の音声データ】\nずっと見たかった映画を見てきました。ストーリーが難解で一回じゃ理解できない部分もあったけど、映像美と音楽の迫力が凄まじくて、とにかく圧倒されました！もう一回見に行きたいです！") do |d|
  d.user = user2
  d.schedule = "昼：映画館で『AIの夜明け』を鑑賞"
  d.content = "【1日の流れ】\n・昼に映画館で新作を鑑賞\n\n【良かったこと】\n・圧倒的な映像美と音楽の迫力\n・もう一度見たいと思えるほどの没入感\n\n【改善点】\n・ストーリーが難解で理解しきれなかった部分がある\n\n【気づき】\n・考察サイトなどを読んでから2回目を見るとさらに楽しめそう"
  d.ai_response = "映画鑑賞お疲れ様でした！ストーリーの難解さに戸惑いつつも、映像と音楽の力で圧倒された体験が伝わってきます。次回はさらに深い視点で楽しめそうですね！"
  d.is_published = true
  d.created_at = 1.day.ago
end

# レビュー2：AIは「難解」「理解できない」というネガティブワードから低く評価。しかしユーザーは「圧倒された」ので自己評価は高め（ギャップ大！）
Review.find_or_create_by!(title: "難解だが圧倒される映像体験") do |r|
  r.user = user2
  r.diary = diary2
  r.campaign = campaign2
  r.body = "ストーリーは一度見ただけではすべてを理解するのが難しいほど複雑でした。しかし、それを補って余りあるほどの圧倒的な映像美と、劇場を揺るがすような音楽に引き込まれます。すべてを理解できなくても、「すごいものを見た」という満足感に浸れる不思議な作品です。"
  r.rating = 4
  r.emotion_score = 2.2      # AIのスコアは低い
  r.user_emotion_score = 4.5 # ユーザーの自己評価は高い
  r.is_published = true
  r.created_at = 1.day.ago
end
AiInterview.find_or_create_by!(diary: diary2) { |i| i.user = user2; i.campaign = campaign2; i.purpose = :review_creation; i.status = :completed; i.created_at = 1.day.ago }

puts "🎉 デモ用データの流し込みが完了しました！管理者ダッシュボードを確認してください！"