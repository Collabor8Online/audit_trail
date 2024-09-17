module AuditTrail
  class Service
    include Plumbing::Actor
    async :record

    private

    def record event_name, partition: nil, user: nil, context: nil, **params, &block
      puts "RECORD #{event_name}"
      context ||= context_stack.current
      partition ||= context&.partition || "event"
      user ||= context&.user

      Event.create!(name: event_name, context: context, partition: partition, data: params, user: user,
        status: "in_progress").tap do |event|
        context_stack.push event
        result = await { block&.call }
        event.update! result: result, status: "completed"
      rescue => e
        event.update! status: "failed", exception: e
      end
    ensure
      context_stack.pop
    end

    def context_stack = AuditTrail.context_stack
  end
end
