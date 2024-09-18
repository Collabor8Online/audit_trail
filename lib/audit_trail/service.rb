module AuditTrail
  class Service
    include Plumbing::Actor
    async :record, :start, :complete, :fail

    private

    def record event_name, user: nil, context: nil, result: nil, **params, &block
      start(event_name, user: user, context: context, **params).tap do |event|
        block&.call event
        complete event, result: result
      rescue => exception
        fail event, exception
      end
    end

    def start event_name, user: nil, context: nil, **params
      Event.create! name: event_name, context: context, data: params, user: user || context&.user, status: "in_progress"
    end

    def complete event, result: nil
      event.complete! result: result
    end

    def fail event, exception
      event.fail! exception
    end
  end
end
