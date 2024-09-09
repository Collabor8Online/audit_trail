module AuditTrail
  class Engine < ::Rails::Engine
    isolate_namespace AuditTrail
  end
end
