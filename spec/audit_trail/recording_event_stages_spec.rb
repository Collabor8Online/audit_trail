require "rails_helper"

RSpec.describe "Recording audit trail events in stages" do
  context "#start" do
    it "records the start of an event" do
      @user = User.create! name: "Alice"
      @post = Post.create! user: @user, title: "Hello world"

      await do
        AuditTrail.service.start "some_event", user: @user, description: "A new post", post: @post
      end

      @event = AuditTrail::Event.last
      expect(@event.name).to eq "some_event"
      expect(@event.user).to eq @user
      expect(@event.data[:description]).to eq "A new post"
      expect(@event.data[:post]).to eq @post

      expect(AuditTrail.current_context).to eq @event
    end

    it "records the start of an event in the context of another event" do
      @user = User.create! name: "Alice"
      @post = Post.create! user: @user, title: "Hello world"

      await do
        AuditTrail.service.record "container_event" do
          AuditTrail.service.start "some_event", user: @user, description: "A new post", post: @post
        end
      end

      @container_event = AuditTrail::Event.find_by name: "container_event"
      @event = AuditTrail::Event.find_by name: "some_event"
      expect(@event.context).to eq @container_event
    end
  end

  context "#complete" do
    it "records the end of an event with a simple result" do
      await do
        AuditTrail.service.start "some_event", description: "A new post"
      end

      await do
        AuditTrail.service.complete result: "DONE"
      end

      @event = AuditTrail::Event.last
      expect(@event.name).to eq "some_event"
      expect(@event.result).to eq "DONE"
    end

    it "records the end of an event with a model result" do
      @user = User.create! name: "Alice"
      await do
        AuditTrail.service.start "some_event", description: "A new post"
      end

      await do
        AuditTrail.service.complete result: @user
      end

      @event = AuditTrail::Event.last
      expect(@event.name).to eq "some_event"
      expect(@event.result).to eq @user
    end

    it "returns to the previous context" do
      expect(AuditTrail.current_context).to be_nil

      await do
        AuditTrail.service.start "some_event", description: "A new post"
      end
      expect(AuditTrail.current_context).to_not be_nil

      await do
        AuditTrail.service.complete result: "DONE"
      end
      expect(AuditTrail.current_context).to be_nil
    end
  end

  context "#fail" do
    it "records that an event failed" do
      await do
        AuditTrail.service.start "some_event", description: "A new post"
      end

      await do
        AuditTrail.service.fail RuntimeError.new("FAIL")
      end

      @event = AuditTrail::Event.last
      expect(@event.name).to eq "some_event"
      expect(@event.exception_class).to eq "RuntimeError"
      expect(@event.exception_message).to eq "FAIL"
    end

    it "returns to the previous context" do
      expect(AuditTrail.current_context).to be_nil

      await do
        AuditTrail.service.start "some_event", description: "A new post"
      end
      expect(AuditTrail.current_context).to_not be_nil

      await do
        AuditTrail.service.fail RuntimeError.new("FAIL")
      end
      expect(AuditTrail.current_context).to be_nil
    end
  end
end
