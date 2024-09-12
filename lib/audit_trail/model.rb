module AuditTrail
  module Model
    extend ActiveSupport::Concern

    included do
      has_many :_linked_models, class_name: "AuditTrail::LinkedModel", as: :model, dependent: :destroy
      has_many :linked_events, through: :_linked_models, source: :event
    end
  end
end
