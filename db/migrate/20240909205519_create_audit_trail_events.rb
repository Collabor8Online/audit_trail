class CreateAuditTrailEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :audit_trail_events do |t|
      t.belongs_to :user, polymorphic: true, index: true
      t.belongs_to :context, null: true, index: true
      t.string :partition, default: "event", null: false
      t.string :name, default: "event", null: false, index: true
      t.integer :status, default: 0, null: false
      t.text :internal_data
      t.timestamps
    end

    add_index :audit_trail_events, [:id, :partition], unique: true
    add_index :audit_trail_events, [:created_at]
  end
end
