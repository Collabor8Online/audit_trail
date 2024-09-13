require "plumbing"
require "audit_trail/context_stack"

module AuditTrail
  def self.context_stack
    Thread.current[:audit_trail_context] ||= ContextStack.new
  end

  def self.events
    @pipe ||= Plumbing::Pipe.start
  end
end

require "audit_trail/version"
require "audit_trail/engine"
require "audit_trail/recording"
require "audit_trail/user"
require "audit_trail/model"
