module AuditTrail
  class LinkedModel < ApplicationRecord
    belongs_to :event, class_name: "AuditTrail::Event"
    belongs_to :model, polymorphic: true
  end
end
