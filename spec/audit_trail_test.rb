require "test_helper"

class AuditTrailTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert AuditTrail::VERSION
  end
end
