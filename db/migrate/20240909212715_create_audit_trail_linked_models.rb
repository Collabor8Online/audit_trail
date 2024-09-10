class CreateAuditTrailLinkedModels < ActiveRecord::Migration[7.2]
  def change
    create_table :audit_trail_linked_models do |t|
      t.string :partition, default: "event", null: false
      t.belongs_to :event, null: false, index: true
      t.belongs_to :model, polymorphic: true, index: true
      t.string :name, default: "", null: false
      t.timestamps
    end

    add_index :audit_trail_linked_models, [:id, :partition], unique: true
  end
end
