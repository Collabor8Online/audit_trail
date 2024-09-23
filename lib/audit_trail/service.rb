module AuditTrail
  class Service
    include Plumbing::Actor
    async :record, :start, :complete, :fail, :current_context, :current_user, :in_context

    def initialize
      @stack = []
    end

    private

    def current_context = @stack.last

    def current_user = current_context&.user

    def record event_name, user: nil, context: nil, result: nil, **params, &block
      start(event_name, user: user, context: context, **params).tap do |event|
        in_context event do
          block&.call event
          complete event, result: result
        rescue => exception
          fail event, exception
        end
      end
    end

    def start event_name, user: nil, context: nil, **params
      context ||= current_context
      user ||= current_user
      Event.create!(name: event_name, context: context, user: user, data: params, status: "in_progress").tap do |event|
        push_context event
      end
    end

    def in_context(event, &)
      safely(&)
    end

    def complete event, result: nil
      event.complete! result: result
    ensure
      pop_context
    end

    def fail event, exception
      event.fail! exception
    ensure
      pop_context
    end

    def push_context(event) = @stack.push(event)

    def pop_context = @stack.pop
  end
end
