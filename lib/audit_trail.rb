require "plumbing"
require "audit_trail/context_stack"

module AuditTrail
  def self.context_stack
    Thread.current[:audit_trail_context] ||= ContextStack.new
  end

  def self.current_context
    context_stack.current
  end

  def self.service
    @service ||= AuditTrail::Service.start
  end

  def self.events
    @pipe ||= Plumbing::Pipe.start
  end

  def self.reset
    @service&.stop
    @service = nil
    @pipe&.stop
    @pipe = nil
    Thread.current[:audit_trail_context] = nil
  end
end

require "audit_trail/version"
require "audit_trail/engine"
require "audit_trail/service"
require "audit_trail/user"
require "audit_trail/model"
