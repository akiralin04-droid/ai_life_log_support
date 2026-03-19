class CreateWeeklyReports < ActiveRecord::Migration[8.0]
  def change
    create_table :weekly_reports do |t|
      t.references :user, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date
      t.text :content

      t.timestamps
    end
  end
end
