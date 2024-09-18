require "rails_helper"

RSpec.describe "AuditTrail.events" do
  it "publishes events when they are started" do
    @result = []
    AuditTrail.events.add_observer do |notification|
      @result << notification.type
    end

    AuditTrail.service.record "some_event"

    expect(true).to become_equal_to { @result.include? "some_event:in_progress" }
  end

  it "publishes events when they are completed" do
    @result = []
    AuditTrail.events.add_observer do |notification|
      @result << notification.type
    end

    AuditTrail.service.record "some_event"

    expect(true).to become_equal_to { @result.include? "some_event:completed" }
  end

  it "publishes events when they fail" do
    @result = []
    AuditTrail.events.add_observer do |notification|
      @result << notification.type
    end

    AuditTrail.service.record "some_event" do
      raise "BOOM"
    end
    expect(true).to become_equal_to { @result.include? "some_event:failed" }
  end
end
