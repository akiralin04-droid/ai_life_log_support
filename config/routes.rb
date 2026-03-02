Rails.application.routes.draw do
  get "campaigns/show"
  get "reviews/index"
  get "reviews/new"
  get "reviews/show"
  get "reviews/edit"
  get "diaries/index"
  get "diaries/new"
  get "diaries/show"
  get "users/index"
  get "users/show"
  get "users/edit"
  get "registrations/new"
  get "searches/search"
  get "homes/top"
  get "homes/about"
  # トップページ & About
  root to: "homes#top"
  get "home/about" => "homes#about", as: "about"

  # 検索
  get "search" => "searches#search"

  # 認証機能 (Rails 8 標準)
  resource :session
  resources :passwords, param: :token
  
  # 新規登録 (カスタム)
  resource :registration, only: [:new, :create]

  # ゲストログイン (カスタム)
  post "session/guest_login" => "sessions#guest_login"

  # ユーザー機能
  resources :users, only: [:index, :show, :edit, :update]

  # 日記機能
  resources :diaries

  # レビュー機能 (AI生成含む)
  resources :reviews do
    collection do
      post :generate # AIによる下書き生成
    end
    # コメント・いいね (非同期)
    resources :comments, only: [:create, :destroy], module: :reviews
    resource :favorites, only: [:create, :destroy], module: :reviews
  end

  # キャンペーン機能
  resources :campaigns, only: [:show]

  # 管理者機能 (Namespace)
  namespace :admin do
    get "dashboards/index"
    get "campaigns/index"
    get "campaigns/new"
    get "campaigns/edit"
    get "reviews/index"
    get "reviews/show"
    get "users/index"
    get "users/show"
    get "/" => "dashboards#index"
    resources :users, only: [:index, :show, :update]
    resources :reviews, only: [:index, :show, :destroy, :update]
    resources :campaigns
  end
end