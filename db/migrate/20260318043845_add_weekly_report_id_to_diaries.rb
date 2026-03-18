class AddWeeklyReportIdToDiaries < ActiveRecord::Migration[8.0]
  def change
    add_reference :diaries, :weekly_report, null: true, foreign_key: true
  end
end
