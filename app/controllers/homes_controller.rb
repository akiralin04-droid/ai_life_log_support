class HomesController < ApplicationController
  # ログインなしでもアクセスして良いページを指定する
  allow_unauthenticated_access only: %i[ top about terms privacy ]

  def top
    # データベースから「公開中(is_active: true)」かつ
    # 「終了日が未来、または終了日が設定されていない」キャンペーンを新着順に3件取得して @active_campaigns に入れる
    @active_campaigns = Campaign.where(is_active: true)
                                .where("end_date >= ? OR end_date IS NULL", Time.current)
                                .order(created_at: :desc)
                                .limit(3)
  end

  def about
  end

  # 利用規約
  def terms
  end

  # プライバシーポリシー
  def privacy
  end

end