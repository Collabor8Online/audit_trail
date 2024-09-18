require "rails_helper"

RSpec.describe AuditTrail::Event do
  it "uses EventData to access its data" do
    @event = described_class.new name: "whatever", internal_data: {some: "values", more: "data", number: 123}

    expect(@event.data).to be_kind_of AuditTrail::EventData
  end

  context "#complete!" do
    it "records the end of an event with a simple result" do
      @event = described_class.create! name: "whatever"

      @event.complete! result: "DONE"

      expect { @event.reload.result }.to become "DONE"
    end

    it "records the end of an event with a model result" do
      @user = User.create! name: "Alice"
      @event = described_class.create! name: "whatever"

      @event.complete! result: @user

      expect { @event.reload.result }.to become @user
    end
  end

  context "#fail!" do
    it "records that an event failed" do
      @event = described_class.create! name: "whatever"

      @event.fail! RuntimeError.new("FAIL")

      expect { @event.exception_class }.to become "RuntimeError"
      expect { @event.exception_message }.to become "FAIL"
    end
  end

  context ".scopes" do
    it "finds events between given dates" do
      @old_event = described_class.create! name: "old", created_at: 2.years.ago
      @middle_event = described_class.create! name: "middle", created_at: 2.days.ago
      @new_event = described_class.create! name: "new"

      @events = described_class.between(7.days.ago, 1.day.ago)

      expect(@events.size).to eq 1
      expect(@events).to include @middle_event
    end

    it "finds events with a given name" do
      @cheetos_1 = described_class.create! name: "cheetos"
      @cheetos_2 = described_class.create! name: "cheetos"
      @wotsits = described_class.create! name: "wotsits"

      @events = described_class.named("cheetos")

      expect(@events.size).to eq 2
      expect(@events).to include @cheetos_1
      expect(@events).to include @cheetos_2
    end

    it "finds events involving a given model" do
      @user = User.create name: "Someone"
      @first_post = Post.create user: @user, title: "Hello"
      @second_post = Post.create user: @user, title: "Goodbye"

      @first_event = described_class.create! name: "post_created", data: {post: @first_post}
      @second_event = described_class.create! name: "post_created", data: {post: @second_post}

      @events = described_class.involving(@second_post)

      expect(@events.size).to eq 1
      expect(@events).to include @second_event
    end

    it "finds events by a given user" do
      @user = User.create name: "Someone"

      @first_event = described_class.create! name: "post_created", user: @user
      @second_event = described_class.create! name: "post_created", user: @user

      @events = described_class.performed_by(@user)

      expect(@events.size).to eq 2
      expect(@events).to include @first_event
      expect(@events).to include @second_event
    end
  end
end
