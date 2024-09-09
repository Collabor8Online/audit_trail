class CreateAuditTrailEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :audit_trail_events do |t|
    t.belongs_to :user, polymorphic: true, index: true
      t.string :partition, default: "event", null: false
      t.string :name, default: "event", null: false, index: true
      t.integer :status, default: 0, null: false
      t.text :data
      t.timestamps
    end

    add_index :audit_trail_events, [:id, :partition], unique: true
  end
end
