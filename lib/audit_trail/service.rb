module AuditTrail
  class Service
    include Plumbing::Actor
    async :record, :start, :complete, :fail

    private

    def record event_name, partition: nil, user: nil, context: nil, result: nil, **params, &block
      start event_name, partition: partition, user: user, context: context, **params
      block&.call
      complete result: result
    rescue => exception
      fail exception
    end

    def start event_name, partition: nil, user: nil, context: nil, **params
      context ||= context_stack.current
      partition ||= context&.partition || "event"
      user ||= context&.user

      Event.create!(name: event_name, context: context, partition: partition, data: params, user: user,
        status: "in_progress").tap do |event|
        context_stack.push event
      end
    end

    def complete result: nil
      context_stack.current&.update! status: "completed", result: result
      context_stack.pop
    end

    def fail exception
      context_stack.current&.update! status: "failed", exception: exception
      context_stack.pop
    end

    def context_stack = AuditTrail.context_stack
  end
end
