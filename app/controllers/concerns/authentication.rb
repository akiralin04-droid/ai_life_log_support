module Authentication
  extend ActiveSupport::Concern

  included do
    # 門番の設置
    # 「全てのページの前に、必ず『ログインしてるか(require_authentication)』をチェックしろ！」という命令
    before_action :require_authentication
    # Viewへの許可証
    # コントローラーの裏方機能である「authenticated?」と「current_user」を
    # 画面（View）でも使えるようにする魔法
    helper_method :authenticated?
    helper_method :current_user
  end

  class_methods do
    # 特例の許可証を発行するメソッド
    # コントローラーで allow_unauthenticated_access を書くと、門番(require_authentication)をスキップできる
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    # ログイン状態か確認する（セッションを復元できるか試す）
    def authenticated?
      resume_session
    end

    # ログインチェック（門番の仕事）
    def require_authentication
      # ログインしてなかったら、強制的にログイン画面へ飛ばす
      resume_session || request_authentication
    end

    # セッションの復元（ポケットから会員証を探すイメージ）
    def resume_session
      Current.session ||= find_session_by_cookie
    end

    # クッキーにあるIDを使って、データベースからセッション情報を探す
    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    # ログイン画面への強制転送
    def request_authentication
      # 「本来行きたかったURL」をメモしておく（ログイン後に連れて行ってあげるため）
      session[:return_to_after_authenticating] = request.url
      # ログイン画面へ飛ばす
      redirect_to new_session_path
    end

    # ログイン後の行き先決定
    def after_authentication_url
      # メモしておいたURLがあればそこへ、なければトップページへ
      session.delete(:return_to_after_authenticating) || root_url
    end

    # ログイン処理（新しい会員証の発行）
    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        # ブラウザに会員証ID（クッキー）を渡す
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    # ログアウト処理（会員証の破棄）
    def terminate_session
      # データベース上のセッション情報を削除
      Current.session.destroy
      # ブラウザ上のクッキーを削除
      cookies.delete(:session_id)
    end

    # 今ログインしているのは誰？（現在のユーザー）
    def current_user
      if defined?(Current) && Current.respond_to?(:session)
        # もしセッション（ログイン情報）があれば、そのユーザーデータを返す
        # （ここが「会員証」を確認している部分です）
        Current.session&.user
      end
    end
end
