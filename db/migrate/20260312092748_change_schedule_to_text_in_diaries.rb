class ChangeScheduleToTextInDiaries < ActiveRecord::Migration[8.0]
  def up
    change_column :diaries, :schedule, :text
  end

  def down
    change_column :diaries, :schedule, :string
  end
end