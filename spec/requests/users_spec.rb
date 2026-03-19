require 'rails_helper'

RSpec.describe "Users", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "PATCH /users/:id" do
    context "自分のアカウント情報を更新する場合" do
      before do
        # ログイン状態を作る
        post session_path, params: { email_address: user.email_address, password: "password" }
      end

      it "カスタムフォーマットを含むプロフィール情報が正しく更新されること" do
        new_name = "アップデートされた名前"
        new_format = "関西弁でフレンドリーに書いてや！"

        patch user_path(user), params: { user: { name: new_name, custom_format: new_format } }

        # DBから最新の情報を取得し直す
        user.reload

        # 更新が成功しているかチェック
        expect(user.name).to eq new_name
        expect(user.custom_format).to eq new_format

        # マイページへリダイレクトされ、成功メッセージが出ること
        expect(response).to redirect_to(mypage_path)
        expect(flash[:notice]).to eq "プロフィールを更新しました。"
      end
    end

    context "他人のアカウント情報を更新しようとした場合" do
      before do
        # user としてログイン
        post session_path, params: { email_address: user.email_address, password: "password" }
      end

      it "更新されず、権限エラーとして弾かれること" do
        # other_user の更新URLを直叩きして攻撃を試みる
        patch user_path(other_user), params: { user: { name: "乗っ取り太郎" } }

        other_user.reload

        # 名前が書き換わっていない（乗っ取り失敗）ことを確認
        expect(other_user.name).not_to eq "乗っ取り太郎"

        # マイページへ強制送還され、エラーメッセージが出ること
        expect(response).to redirect_to(mypage_path)
        expect(flash[:alert]).to eq "権限がありません。"
      end
    end
  end
end