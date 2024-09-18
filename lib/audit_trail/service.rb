module AuditTrail
  class Service
    include Plumbing::Actor
    async :record, :start, :complete, :fail

    private

    def record event_name, user: nil, context: nil, result: nil, **params, &block
      start event_name, user: user, context: context, **params
      block&.call
      complete result: result
    rescue => exception
      fail exception
    end

    def start event_name, user: nil, context: nil, **params
      context ||= context_stack.current
      user ||= context&.user

      Event.create!(name: event_name, context: context, data: params, user: user,
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
