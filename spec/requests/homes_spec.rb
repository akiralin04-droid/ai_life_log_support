require 'rails_helper'

RSpec.describe "Homes", type: :request do
  describe "未ログイン時のアクセス権限" do
    
    it "トップページ (GET /) にアクセスできること" do
      get root_path
      expect(response).to have_http_status(:success)
    end

    it "利用規約 (GET /home/terms) にアクセスできること" do
      get terms_path
      expect(response).to have_http_status(:success)
    end

    it "プライバシーポリシー (GET /home/privacy) にアクセスできること" do
      get privacy_path
      expect(response).to have_http_status(:success)
    end

  end
end