# frozen_string_literal: true

module AuditTrail
  class Event < ApplicationRecord
    belongs_to :context, class_name: "AuditTrail::Event", optional: true
    has_many :children, class_name: "AuditTrail::Event", foreign_key: "context_id", dependent: :nullify
    belongs_to :user, polymorphic: true, optional: true
    has_many :links, class_name: "AuditTrail::LinkedModel", dependent: :destroy
    validates :name, presence: true
    validates :partition, presence: true
    serialize :data, type: Hash, coder: YAML, default: {}
    enum :status, ready: 0, in_progress: 10, completed: 100, failed: -1

    def result
      result_as_value || result_as_model
    end

    def result= value
      value.is_a?(ActiveRecord::Base) ? record_result_as_model(value) : record_result_as_value(value)
    end

    def exception= value
      data[EXCEPTION_CLASS_NAME] = value.class.name
      data[EXCEPTION_MESSAGE] = value.message
    end

    def exception_class = data[EXCEPTION_CLASS_NAME]

    def exception_message = data[EXCEPTION_MESSAGE]

    private

    def result_as_value = data[RESULT]

    def result_as_model
      links.find_by(name: RESULT)&.model
    end

    def record_result_as_value(value)
      value.nil? ? data.delete(RESULT) : data[RESULT] = value
    end

    def record_result_as_model(model)
      links.create! name: RESULT, partition: partition, model: model
    end

    RESULT = "audit_trail/event/result"
    EXCEPTION_CLASS_NAME = "audit_trail/event/exception_class"
    EXCEPTION_MESSAGE = "audit_trail/event/exception_message"
  end
end
