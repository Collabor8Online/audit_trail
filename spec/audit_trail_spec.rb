require "spec_helper"

RSpec.describe AuditTrail do
  it "has a version number" do
    expect(AuditTrail::VERSION).to_not be_nil
  end
end
