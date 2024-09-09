Rails.application.routes.draw do
  mount AuditTrail::Engine => "/audit_trail"
end
