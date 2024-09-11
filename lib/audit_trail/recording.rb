require_relative "context_stack"

module AuditTrail
  def self.record event_name, partition: nil, user: nil, context: nil, **params, &block
    context ||= context_stack.current
    partition ||= context&.partition || "event"
    user ||= context&.user

    models = params.select { |key, value| value.is_a? ActiveRecord::Base }
    data = params.select { |key, value| !value.is_a? ActiveRecord::Base }

    Event.create!(name: event_name, context: context, partition: partition, user: user, internal_data: data, status: "in_progress").tap do |event|
      begin
        context_stack.push event

        models.each { |key, model| event.links.create! name: key, model: model, partition: partition }

        event.update result: block&.call, status: "completed"
      rescue => ex
        event.update status: "failed", exception: ex
      ensure
        context_stack.pop
      end
    end
  end

  def self.context_stack
    Thread.current[:audit_trail_context] ||= ContextStack.new
  end
end
