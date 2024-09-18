require "rails_helper"

RSpec.describe "Recording audit trail events within the context of other events" do
  context "#context" do
    it "records an event within the context of another event" do
      AuditTrail.service.record "some_event" do
        AuditTrail.service.record "another_event"
      end

      wait_for { @event = AuditTrail::Event.find_by name: "another_event" }
      expect(@event.context.name).to eq "some_event"
    end

    it "records a hierarchy of events" do
      AuditTrail.service.record "event" do
        AuditTrail.service.record "child" do
          AuditTrail.service.record "grandchild"
        end
      end

      wait_for { @event = AuditTrail::Event.find_by name: "grandchild" }
      expect(@event.context.name).to eq "child"
      expect(@event.context.context.name).to eq "event"
    end

    it "tracks the current context" do
      AuditTrail.service.record "some_event" do
        @event = AuditTrail::Event.find_by! name: "some_event"
        expect(AuditTrail.current_context).to eq @event

        AuditTrail.service.service.record "another_event" do
          @another_event = AuditTrail::Event.find_by! name: "another_event"
          expect(AuditTrail.current_context).to eq @another_event
        end
      end
    end

    it "removes the current context when an event completes" do
      AuditTrail.service.record "some_event" do
        @event = AuditTrail::Event.find_by! name: "some_event"

        AuditTrail.service.record "another_event" do
          raise "FAILURE"
        end

        expect(AuditTrail.current_context).to eq @event

        raise "ANOTHER FAILURE"
      end

      expect(AuditTrail.current_context).to be_nil
    end

    it "removes the current context when an event fails" do
      AuditTrail.service.record "some_event" do
        @event = AuditTrail::Event.find_by! name: "some_event"
        AuditTrail.service.record "another_event" do
          @another_event = AuditTrail::Event.find_by! name: "another_event"
          expect(AuditTrail.current_context).to eq @another_event
        end
        expect(AuditTrail.current_context).to eq @event
      end
      expect(AuditTrail.current_context).to be_nil
    end
  end

  context "#status" do
    it "marks the event as in progress" do
      AuditTrail.service.record "some_event" do
        @event = AuditTrail::Event.last
        expect(@event).to be_in_progress
      end
    end

    it "marks the event as completed" do
      AuditTrail.service.record "some_event"

      wait_for { @event = AuditTrail::Event.find_by name: "some_event" }
      expect(@event).to be_completed
    end

    it "marks the event as failed" do
      AuditTrail.service.record "some_event" do
        raise "BOOM"
      end

      wait_for { @event = AuditTrail::Event.find_by name: "some_event" }
      expect(@event).to be_failed
    end
  end

  context "#result" do
    it "records the result of the event as a simple type" do
      AuditTrail.service.record "some_event", result: :the_result

      wait_for { @event = AuditTrail::Event.find_by name: "some_event" }
      expect(@event.result).to eq :the_result
    end

    it "records the result of the event as a linked model" do
      @some_user = User.create! name: "Some person"

      AuditTrail.service.record "some_event", result: @some_user

      wait_for { @event = AuditTrail::Event.find_by name: "some_event" }
      expect(@event.result).to eq @some_user
    end
  end

  context "#exception" do
    it "records the exception that caused the failure" do
      AuditTrail.service.record "some_event" do
        raise "BOOM"
      end

      wait_for { @event = AuditTrail::Event.find_by name: "some_event" }
      expect(@event.exception_class).to eq "RuntimeError"
      expect(@event.exception_message).to eq "BOOM"
    end
  end

  context "inheritance" do
    it "inherits the user from the current context" do
      @user = User.create! name: "Some person"
      @other_user = User.create! name: "Someone else"

      AuditTrail.service.record "some_event", user: @user do
        AuditTrail.service.record "another_event", user: @other_user
      end

      wait_for { @event = AuditTrail::Event.find_by name: "another_event" }
      expect(@event.user).to eq @other_user
    end
  end
end
