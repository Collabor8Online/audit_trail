module AuditTrail
  module User
    extend ActiveSupport::Concern

    included do
      has_many :events, class_name: "AuditTrail::Event", dependent: :destroy
    end
  end
end
