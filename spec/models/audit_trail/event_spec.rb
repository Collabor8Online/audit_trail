require "rails_helper"

RSpec.describe AuditTrail::Event do
  it "uses EventData to access its data" do
    @event = described_class.new name: "whatever", internal_data: { some: "values", more: "data", number: 123 }

    expect(@event.data).to be_kind_of AuditTrail::EventData
  end
end
