class AddScheduleAndRawVoiceToDiaries < ActiveRecord::Migration[8.0]
  def change
    add_column :diaries, :schedule, :string
    add_column :diaries, :raw_voice_text, :text
  end
end
