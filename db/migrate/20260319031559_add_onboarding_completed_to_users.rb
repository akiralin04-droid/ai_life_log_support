class AddOnboardingCompletedToUsers < ActiveRecord::Migration[8.0]
  def change
    # デフォルトを false にして、既存のユーザーも含めて初回は必ず表示されるようにします
    add_column :users, :onboarding_completed, :boolean, default: false, null: false
  end
end
