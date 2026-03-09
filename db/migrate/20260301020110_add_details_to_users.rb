class AddDetailsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name, :string
    add_column :users, :introduction, :text
    # role にデフォルト値 0 を設定
    add_column :users, :role, :integer, default: 0, null: false
  end
end
