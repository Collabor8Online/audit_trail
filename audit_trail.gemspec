require_relative "lib/audit_trail/version"

Gem::Specification.new do |spec|
  spec.name = "c8o_audit_trail"
  spec.version = AuditTrail::VERSION
  spec.authors = ["Rahoul Baruah"]
  spec.email = ["baz@collabor8online.co.uk"]
  spec.homepage = "https://www.collabor8online.co.uk"
  spec.summary = "Audit Trail"
  spec.description = "Audit Trail for Collabor8Online"

  spec.metadata["allowed_push_host"] = "https://gems.c8online.net"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/collabor8online/c8o2"
  spec.metadata["changelog_uri"] = "https://github.com/collabor8online/c8o2"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.1.3.4"
  # spec.add_dependency "standard-procedure-plumbing"
end
