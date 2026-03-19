require 'rails_helper'

RSpec.describe "Diaries", type: :request do
  let(:user) { create(:user) }

  before do
    # ログイン状態を作る
    post session_path, params: { email_address: user.email_address, password: "password" }
  end

  describe "POST /diaries (日記の作成)" do
    context "タブ1: 音声入力(raw_voice_text)で送信した場合" do
      it "AIチャットをスキップして、直接finalize(清書処理)へリダイレクトされること" do
        voice_data = "今日は最高の一日だった！"

        # データベースの日記(Diary)とインタビュー(AiInterview)の数が1つ増えることを確認
        expect {
          post diaries_path, params: { diary: { raw_voice_text: voice_data } }
        }.to change(Diary, :count).by(1).and change(AiInterview, :count).by(1)

        interview = AiInterview.last

        # AIではなく、ユーザーの音声データが最初のメッセージとして保存されていること
        expect(interview.ai_messages.first.role).to eq "user"
        expect(interview.ai_messages.first.content).to eq voice_data

        # チャット画面ではなく、finalize（日記完成処理）へ直接強制ジャンプしていること
        expect(response).to redirect_to(finalize_ai_interview_path(interview))
        expect(flash[:notice]).to eq "音声データを送信しました。AIが日記を生成しています...✨"
      end
    end

    context "タブ2: スケジュール(schedule)のみ入力して送信した場合" do
      it "AIが1つ目の質問を作成し、チャット画面へリダイレクトされること" do
        # 【超重要：モック（偽物）の作成】
        # 本物のOpenAI APIにお金を払って通信するのを防ぐため、
        # 「API通信が成功して、こういう返事が返ってきたことにする」という偽物のクライアントを作ります。
        mock_client = instance_double(OpenAI::Client)
        allow(OpenAI::Client).to receive(:new).and_return(mock_client)
        allow(mock_client).to receive(:chat).and_return(
          { "choices" =>[ { "message" => { "content" => "モックされたAIの質問です！" } } ] }
        )

        # テスト実行
        expect {
          post diaries_path, params: { diary: { schedule: "朝: カフェ\n昼: 読書" } }
        }.to change(Diary, :count).by(1).and change(AiMessage, :count).by(1)

        interview = AiInterview.last

        # 保存されたAIのメッセージが、モック（偽物）の通りになっていること
        expect(interview.ai_messages.last.role).to eq "assistant"
        expect(interview.ai_messages.last.content).to eq "モックされたAIの質問です！"

        # ちゃんとチャット画面（AIとの対話）へジャンプしていること
        expect(response).to redirect_to(ai_interview_path(interview))
        expect(flash[:notice]).to eq "AIがスケジュールを分析し、質問を作成しました！✨"
      end
    end
  end
end