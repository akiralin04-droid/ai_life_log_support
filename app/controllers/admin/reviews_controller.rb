class Admin::ReviewsController < ApplicationController
  before_action :require_admin
  before_action :set_review, only: %i[show update destroy]

  def index
    @q = Review.ransack(params[:q])
    @q.sorts = 'created_at desc' if @q.sorts.empty?
    @reviews = @q.result(distinct: true).page(params[:page]).per(20)
  end

  def show
  end

  def update
    if @review.update(review_params)
      redirect_to admin_review_path(@review), notice: "レビューのステータスを更新しました。"
    else
      redirect_to admin_review_path(@review), alert: "更新に失敗しました。"
    end
  end

  def destroy
    @review.destroy
    redirect_to admin_reviews_path, notice: "不適切なレビューを削除しました。", status: :see_other
  end

  private

  def require_admin
    redirect_to root_path, alert: "管理者権限がありません。" unless current_user.admin?
  end

  def set_review
    @review = Review.find(params[:id])
  end

  def review_params
    # 管理者画面からは、is_published（公開フラグ）のみ変更できるように許可する
    params.require(:review).permit(:is_published)
  end
end