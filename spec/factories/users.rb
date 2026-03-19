FactoryBot.define do
  factory :user do
    name { "テストユーザー" }
    # 複数人作ってもメアドが被らないように、test1, test2...と連番にする魔法です
    sequence(:email_address) { |n| "test#{n}@example.com" }
    password { "password" }
    password_confirmation { "password" }
    role { :general } # デフォルトは一般ユーザー

    # 管理者を作りたい時のオプション
    trait :admin do
      name { "管理者ユーザー" }
      role { :admin }
    end
  end
end