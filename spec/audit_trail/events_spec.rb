require "rails_helper"

RSpec.describe "AuditTrail.events" do
  it "publishes events when they are started" do
    @result = []
    AuditTrail.events.add_observer do |notification|
      @result << notification.type
    end

    await do
      AuditTrail.service.record "some_event"
    end
    expect(@result).to include "some_event:in_progress"
  end

  it "publishes events when they are completed" do
    @result = []
    AuditTrail.events.add_observer do |notification|
      @result << notification.type
    end

    await do
      AuditTrail.service.record "some_event"
    end
    # and check the result of the final event notification
    expect(@result).to include "some_event:completed"
  end

  it "publishes events when they fail" do
    @result = []
    AuditTrail.events.add_observer do |notification|
      @result << notification.type
    end

    await do
      AuditTrail.service.record "some_event" do
        raise "BOOM"
      end
    end
    # and check the result of the final event notification
    expect(@result).to include "some_event:failed"
  end
end
