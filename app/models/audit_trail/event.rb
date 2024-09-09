module AuditTrail
  class Event < ApplicationRecord
    belongs_to :user, polymorphic: true, optional: true
    has_many :links, class_name: "AuditTrail::LinkedModel", dependent: :destroy
    validates :name, presence: true
    validates :partition, presence: true
    serialize :data, type: Hash, coder: YAML, default: {}
    enum :status, ready: 0, in_progress: 10, completed: 100, failed: -1
  end
end
