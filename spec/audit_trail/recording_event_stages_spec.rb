require "rails_helper"

RSpec.describe "Recording audit trail events in stages" do
  context "#start" do
    it "records the start of an event" do
      @user = User.create! name: "Alice"
      @post = Post.create! user: @user, title: "Hello world"

      AuditTrail.service.start "some_event", user: @user, description: "A new post", post: @post

      expect { AuditTrail.current_context }.to become @event

      wait_for { @event = AuditTrail::Event.find_by name: "some_event" }
      expect(@event.user).to eq @user
      expect(@event.data[:description]).to eq "A new post"
      expect(@event.data[:post]).to eq @post
    end

    it "records the start of an event in the context of another event" do
      @user = User.create! name: "Alice"
      @post = Post.create! user: @user, title: "Hello world"

      AuditTrail.service.record "container_event" do
        AuditTrail.service.start "some_event", user: @user, description: "A new post", post: @post
      end

      wait_for { @container_event = AuditTrail::Event.find_by name: "container_event" }
      @event = AuditTrail::Event.find_by name: "some_event"
      expect(@event.context).to eq @container_event
    end
  end

  context "#complete" do
    it "records the end of an event with a simple result" do
      AuditTrail.service.start "some_event", description: "A new post"

      AuditTrail.service.complete result: "DONE"

      wait_for { @event = AuditTrail::Event.find_by name: "some_event" }
      expect { @event.reload.result }.to become "DONE"
    end

    it "records the end of an event with a model result" do
      @user = User.create! name: "Alice"
      AuditTrail.service.start "some_event", description: "A new post"

      AuditTrail.service.complete result: @user

      wait_for { @event = AuditTrail::Event.find_by name: "some_event" }
      expect { @event.reload.result }.to become @user
    end

    it "returns to the previous context" do
      expect(AuditTrail.current_context).to be_nil

      AuditTrail.service.start "some_event", description: "A new post"
      AuditTrail.service.complete result: "DONE"

      expect { AuditTrail.current_context }.to become nil
    end
  end

  context "#fail" do
    it "records that an event failed" do
      AuditTrail.service.start "some_event", description: "A new post"

      AuditTrail.service.fail RuntimeError.new("FAIL")

      wait_for { @event = AuditTrail::Event.find_by name: "some_event" }
      expect(@event.exception_class).to eq "RuntimeError"
      expect(@event.exception_message).to eq "FAIL"
    end

    it "returns to the previous context" do
      expect(AuditTrail.current_context).to be_nil

      AuditTrail.service.start "some_event", description: "A new post"
      AuditTrail.service.fail RuntimeError.new("FAIL")

      expect { AuditTrail.current_context }.to become nil
    end
  end
end
