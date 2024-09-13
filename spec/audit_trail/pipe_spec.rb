require "rails_helper"

RSpec.describe "AuditTrail.events" do
  it "publishes events when they are started" do
    Plumbing.configure mode: :inline

    @result = nil
    AuditTrail.events.add_observer do |notification|
      @result = notification.type
    end

    AuditTrail.record "some_event" do
      expect(@result).to eq "some_event.started"
    end
  end
  it "publishes events when they are completed"
  it "publishes events when they fail"
end
