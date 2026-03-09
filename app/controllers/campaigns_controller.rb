class CampaignsController < ApplicationController
  # ログインしていなくてもキャンペーンの詳細は見られるように設定（任意）
  allow_unauthenticated_access only: %i[ show ]

  def show
    # URLの :id から対象のキャンペーンを探す
    @campaign = Campaign.find(params[:id])
  end
end