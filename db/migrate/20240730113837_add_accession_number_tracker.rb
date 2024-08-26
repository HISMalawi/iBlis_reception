class AddAccessionNumberTracker < ActiveRecord::Migration
  def change
    create_table :accession_number_trackers do |t|
      t.string :day, default: "#{Date.today.strftime('%Y%m%d')}"
      t.integer :acc_num_count, default: 1
      t.timestamps
    end
    add_index :accession_number_trackers, %i[day acc_num_count], unique: true
  end
end
