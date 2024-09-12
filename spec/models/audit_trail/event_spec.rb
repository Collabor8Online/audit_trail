require "rails_helper"

RSpec.describe AuditTrail::Event do
  it "uses EventData to access its data" do
    @event = described_class.new name: "whatever", internal_data: {some: "values", more: "data", number: 123}

    expect(@event.data).to be_kind_of AuditTrail::EventData
  end

  context ".scopes" do
    it "finds events between given dates" do
      @old_event = AuditTrail::Event.create! name: "old", created_at: 2.years.ago
      @middle_event = AuditTrail::Event.create! name: "middle", created_at: 2.days.ago
      @new_event = AuditTrail::Event.create! name: "new"

      @events = AuditTrail::Event.between(7.days.ago, 1.day.ago)

      expect(@events.size).to eq 1
      expect(@events).to include @middle_event
    end

    it "finds events with a given name" do
      @cheetos_1 = AuditTrail::Event.create! name: "cheetos"
      @cheetos_2 = AuditTrail::Event.create! name: "cheetos"
      @wotsits = AuditTrail::Event.create! name: "wotsits"

      @events = AuditTrail::Event.named("cheetos")

      expect(@events.size).to eq 2
      expect(@events).to include @cheetos_1
      expect(@events).to include @cheetos_2
    end

    it "finds events involving a given model" do
      @user = User.create name: "Someone"
      @first_post = Post.create user: @user, title: "Hello"
      @second_post = Post.create user: @user, title: "Goodbye"
      @first_event = AuditTrail.record "post_created", post: @first_post
      @second_event = AuditTrail.record "post_created", post: @second_post

      @events = AuditTrail::Event.involving(@second_post)

      expect(@events.size).to eq 1
      expect(@events).to include @second_event
    end
  end
end
