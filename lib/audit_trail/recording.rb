module AuditTrail
  def self.record event_name, partition: nil, user: nil, context: nil, **params, &block
    context ||= current_context
    partition ||= context&.partition || "event"
    user ||= context&.user

    models = params.select { |key, value| value.is_a? ActiveRecord::Base }
    data = params.select { |key, value| !value.is_a? ActiveRecord::Base }

    Event.create!(name: event_name, context: context, partition: partition, user: user, data: data, status: "in_progress").tap do |event|

      begin
        push_context event

        models.each { |key, model| event.links.create! name: key, model: model, partition: partition }

        event.update result: block&.call, status: "completed"
      rescue => ex
        event.update status: "failed", exception: ex
      ensure
        pop_context
      end
    end
  end

  def self.call_in_context event, &block
    push_context event
    event.result = block.call
  ensure
    pop_context
  end

  def self.current_context
    context_stack.last
  end

  def self.push_context context
    context_stack << context
  end

  def self.pop_context
    context_stack.pop
  end

  def self.context_stack
    Thread.current[:audit_trail_context_stack] ||= []
  end
end
