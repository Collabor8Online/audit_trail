require "plumbing"

# frozen_string_literal: true

module AuditTrail
  class Event < ApplicationRecord
    scope :between, ->(starts_at, ends_at) { where(created_at: starts_at..ends_at) }
    scope :involving, ->(model) { includes(:links).where(links: {model: model}) }
    scope :named, ->(name) { where(name: name) }
    scope :performed_by, ->(user) { where(user: user) }

    belongs_to :context, class_name: "AuditTrail::Event", optional: true
    has_many :children, class_name: "AuditTrail::Event", foreign_key: "context_id", dependent: :nullify
    belongs_to :user, polymorphic: true, optional: true
    has_many :links, class_name: "AuditTrail::LinkedModel", dependent: :destroy
    validates :name, presence: true
    validates :partition, presence: true
    serialize :internal_data, type: Hash, coder: YAML, default: {}
    enum :status, ready: 0, in_progress: 10, completed: 100, failed: -1

    after_save do
      AuditTrail.events.notify "#{name}:#{status}", self
    end

    def result
      result_as_value || result_as_model
    end

    def result= value
      value.is_a?(ActiveRecord::Base) ? record_result_as_model(value) : record_result_as_value(value)
    end

    def exception= value
      internal_data[EXCEPTION_CLASS_NAME] = value.class.name
      internal_data[EXCEPTION_MESSAGE] = value.message
    end

    def exception_class = internal_data[EXCEPTION_CLASS_NAME]

    def exception_message = internal_data[EXCEPTION_MESSAGE]

    def data = @data ||= EventData.new(self)

    def data=(value)
      data.apply value
    end

    private

    def result_as_value = internal_data[RESULT]

    def result_as_model
      links.find_by(name: RESULT)&.model
    end

    def record_result_as_value(value)
      value.nil? ? internal_data.delete(RESULT) : internal_data[RESULT] = value
    end

    def record_result_as_model(model)
      links.create! name: RESULT, partition: partition, model: model
    end

    RESULT = "audit_trail/event/result"
    EXCEPTION_CLASS_NAME = "audit_trail/event/exception_class"
    EXCEPTION_MESSAGE = "audit_trail/event/exception_message"
  end
end
