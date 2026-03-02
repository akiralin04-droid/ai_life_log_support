class HomesController < ApplicationController
  # ログインなしでもアクセスして良いページを指定する
  allow_unauthenticated_access only: %i[ top about ]

  def top
  end

  def about
  end
end