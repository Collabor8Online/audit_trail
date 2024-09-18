require "plumbing"

module AuditTrail
  def self.service
    @service ||= AuditTrail::Service.start
  end

  def self.events
    @pipe ||= Plumbing::Pipe.start
  end
end

require "audit_trail/version"
require "audit_trail/engine"
require "audit_trail/service"
require "audit_trail/user"
require "audit_trail/model"
