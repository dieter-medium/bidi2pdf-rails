class CreateReportResults < ActiveRecord::Migration[8.0]
  def change
    create_table :report_results do |t|
      t.string :report_id, null: false
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end
    add_index :report_results, :report_id, unique: true
  end
end
