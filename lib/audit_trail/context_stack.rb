module AuditTrail
  class ContextStack
    def initialize
      @stack = []
    end

    def push event
      @stack << event
    end

    def pop
      @stack.pop
    end

    def current
      @stack.last
    end
  end
end
