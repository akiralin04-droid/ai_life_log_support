module Reviews
  class FavoritesController < ApplicationController
    before_action :set_review

    def create
      # いいねを作成
      @review.favorites.create(user_id: current_user.id)
      
      # TurboStreamを使って、ボタン部分だけを更新する
      render turbo_stream: turbo_stream.replace(
        "favorite_btn_#{@review.id}",
        partial: "reviews/favorites/btn",
        locals: { review: @review }
      )
    end

    def destroy
      # いいねを削除
      favorite = @review.favorites.find_by(user_id: current_user.id)
      favorite&.destroy

      # TurboStreamを使って、ボタン部分だけを更新する
      render turbo_stream: turbo_stream.replace(
        "favorite_btn_#{@review.id}",
        partial: "reviews/favorites/btn",
        locals: { review: @review }
      )
    end

    private

    def set_review
      @review = Review.find(params[:review_id])
    end
  end
end