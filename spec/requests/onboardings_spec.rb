require 'rails_helper'

RSpec.describe "Onboardings", type: :request do
  let(:user) { create(:user, onboarding_completed: false) }

  describe "PATCH /onboarding" do
    context "ログインしている場合" do
      before do
        # ログイン状態を作る
        post session_path, params: { email_address: user.email_address, password: "password" }
      end

      it "onboarding_completed が true に更新され、トップページにリダイレクトされること" do
        patch onboarding_path

        # データベースから最新のユーザー情報を取得し直してチェック
        user.reload
        expect(user.onboarding_completed).to be true

        # 完了メッセージとともにトップページへリダイレクトされること
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq "チュートリアルを完了しました！さっそく記録を始めましょう。"
      end
    end

    context "未ログインの場合" do
      it "更新されず、ログイン画面に強制送還されること" do
        patch onboarding_path

        user.reload
        expect(user.onboarding_completed).to be false
        # ▼▼▼ トップページではなく、ログイン画面に変更 ▼▼▼
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end