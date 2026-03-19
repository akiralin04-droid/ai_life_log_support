require 'rails_helper'

RSpec.describe "Admin::Dashboards", type: :request do
  describe "GET /admin (管理者ダッシュボードへのアクセス)" do
    
    context "未ログインのユーザーがアクセスした場合" do
      it "ログイン画面に強制送還されること" do
        get "/admin"
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "一般ユーザーとしてログインしている場合" do
      let(:user) { create(:user) } # FactoryBotで一般ユーザーを作成

      before do
        # Rails8の標準機能に合わせて、ログイン画面にデータを投げてログイン状態を作る
        post session_path, params: { email_address: user.email_address, password: "password" }
      end

      it "トップページに強制送還され、警告メッセージが出ること" do
        get "/admin"
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq "管理者権限がありません。"
      end
    end

    context "管理者としてログインしている場合" do
      let(:admin_user) { create(:user, :admin) } # FactoryBotで管理者を作成

      before do
        post session_path, params: { email_address: admin_user.email_address, password: "password" }
      end

      it "正常にダッシュボードが表示されること (ステータスコード200)" do
        get "/admin"
        expect(response).to have_http_status(:success)
      end
    end

  end
end