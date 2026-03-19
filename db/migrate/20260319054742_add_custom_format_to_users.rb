class AddCustomFormatToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :custom_format, :text
  end
end
