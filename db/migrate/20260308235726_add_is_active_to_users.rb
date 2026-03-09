class AddIsActiveToUsers < ActiveRecord::Migration[8.0]
  def change
    # default: true（最初から有効）と null: false（空っぽを許さない）を追加
    add_column :users, :is_active, :boolean, default: true, null: false
  end
end