class CreateUnsyncOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :unsync_orders do |t|
      t.string :specimen_id, null: false
      t.string :data_not_synced, :limit => 2000
      t.string :data_level
      t.string :sync_status
      t.string :updated_by_name
      t.string :updated_by_id
      t.timestamps
    end
  end
end
