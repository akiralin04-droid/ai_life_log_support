Rails.application.routes.draw do
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

  # マイページ 
  resource :mypage, only: [:show]
  resources :weekly_reports, only:[:show, :create, :destroy]
  
  # 日記機能
  resources :diaries do
    # ▼▼▼ 追加: コレクションルーティング ▼▼▼
    collection do
      get :public_index # 「みんなの日記」用のアクション
    end
  end


  # レビュー機能 (AI生成含む)
  resources :reviews do
    collection do
      # ↓↓↓ これを追加（詳細入力画面）
      get :select_type 
      post :generate # AIによる下書き生成
    end
    # コメント・いいね (非同期)
    resources :comments, only: [:create, :destroy], module: :reviews
    resource :favorites, only: [:create, :destroy], module: :reviews
  end

  # AIチャット・インタビュー機能
  resources :ai_interviews, only: [:show, :create] do
    resources :ai_messages, only: [:create] # チャット内でメッセージを送信するため
    member do
      get :finalize  # 💡 追加 (自動遷移用)
      post :finalize # 💡 (ボタン用)
    end
  end

  # キャンペーン機能
  resources :campaigns, only: [:show]

  # 管理者機能 (Namespace)
  namespace :admin do
    get "/" => "dashboards#index"

    # ユーザー・レビュー・日記・キャンペーンの管理（resourcesにまとめる）
    resources :users, only:[:index, :show, :update]
    resources :reviews, only: [:index, :show, :destroy, :update]
    resources :diaries, only: [:index, :show, :destroy, :update]
    resources :campaigns
  end

  # オンボーディング完了用のルーティング（更新のみ）
  resource :onboarding, only: [:update]

end