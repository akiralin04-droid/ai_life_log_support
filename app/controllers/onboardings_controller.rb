class OnboardingsController < ApplicationController

  def update
    if current_user
      # ログインできている場合のみ、完了フラグを true に更新
      current_user.update_column(:onboarding_completed, true)
      
      # トップページに戻って完了メッセージを表示
      redirect_to root_path, notice: "チュートリアルを完了しました！さっそく記録を始めましょう。", status: :see_other
    else
      # 万が一エラー等で未ログインだった場合
      redirect_to root_path, status: :see_other
    end
  end
  
end