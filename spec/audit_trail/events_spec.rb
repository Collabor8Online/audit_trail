require "rails_helper"

RSpec.describe "AuditTrail.events" do
  it "publishes events when they are started" do
    @result = nil
    AuditTrail.events.add_observer do |notification|
      @result = notification.type
    end

    AuditTrail.service.record "some_event" do
      expect(@result).to eq "some_event:in_progress"
    end
  end

  it "publishes events when they are completed" do
    @result = nil
    AuditTrail.events.add_observer do |notification|
      @result = notification.type
    end

    AuditTrail.service.record "some_event" do
      # ignore the stuff in here
    end
    # and check the result of the final event notification
    expect(@result).to eq "some_event:completed"
  end

  it "publishes events when they fail" do
    @result = nil
    AuditTrail.events.add_observer do |notification|
      @result = notification.type
    end

    AuditTrail.service.record "some_event" do
      raise "BOOM"
    end
    # and check the result of the final event notification
    expect(@result).to eq "some_event:failed"
  end
end
