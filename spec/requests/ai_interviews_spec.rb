require 'rails_helper'

RSpec.describe "AiInterviews", type: :request do
  # 必要なデータ（ユーザー、空の日記、インタビュー枠）をテスト用に作成
  let(:user) { create(:user) }
  let(:diary) { Diary.create!(user: user, schedule: "テストの予定") }
  let(:ai_interview) { AiInterview.create!(user: user, diary: diary, purpose: :diary_creation) }

  before do
    # ログイン状態を作る
    post session_path, params: { email_address: user.email_address, password: "password" }
    
    # ユーザーが一生懸命マイクに向かって話した「音声データ（会話履歴）」を作成
    AiMessage.create!(ai_interview: ai_interview, role: :user, content: "これは絶対に消えてほしくない、大切な音声データです！")
  end

  describe "POST /ai_interviews/:id/finalize (日記の清書処理)" do
    context "OpenAIのAPIが混雑でタイムアウト（エラー）を起こした場合" do
      
      it "アプリがクラッシュせず、ユーザーの音声データが保護されて日記画面へリダイレクトされること" do
        
        # 【超重要：エラーのモック（偽装）】
        # OpenAIの通信が呼ばれた瞬間、意図的に「API Timeout Error!」という強烈なエラーを発生させる
        mock_client = instance_double(OpenAI::Client)
        allow(OpenAI::Client).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:chat).and_raise(StandardError, "API Timeout Error!")

        # 同じく、感情分析サービス（AiSummaryService）も連鎖してエラーを吐くように偽装する
        mock_summary = instance_double(AiSummaryService)
        allow(AiSummaryService).to receive(:new).and_return(mock_summary)
        allow(mock_summary).to receive(:call).and_raise(StandardError, "Summary Timeout Error!")

        # いざ、エラーが起きるはずの「日記作成処理」を実行！
        post finalize_ai_interview_path(ai_interview)

        # データベースの最新状態を取得して、データがどうなったか確認
        diary.reload
        ai_interview.reload

        # 【結果検証1】フェイルセーフが作動し、本文に「失敗しました」という説明とともに、
        # ユーザーの生データ（絶対に消えてほしくないデータ）がちゃんと保存されていること！
        expect(diary.content).to include "（AIでの日記生成に失敗しました"
        expect(diary.content).to include "これは絶対に消えてほしくない、大切な音声データです！"
        
        # 【結果検証2】感情分析の失敗メッセージも綺麗に保存されていること
        expect(diary.ai_response).to eq "（現在AIが混雑しており、分析レポートの生成にタイムアウトしました。後ほど編集画面からお試しください）"

        # 【結果検証3】インタビュー自体は「完了(completed)」扱いになり、次に進めること
        expect(ai_interview.status).to eq "completed"

        # 【結果検証4】恐ろしい500エラー画面にならず、正常に日記の詳細画面へジャンプできていること！
        expect(response).to redirect_to(diary_path(diary))
      end
    end
  end
end