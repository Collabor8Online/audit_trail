require "rails_helper"

RSpec.describe "Recording audit trail events within the context of other events" do
  Plumbing::Spec.modes do
    context "In #{Plumbing.config.mode} mode" do
      context "#context" do
        it "records an event within the context of another event" do
          AuditTrail.service.record "some_event" do |context|
            AuditTrail.service.record "another_event", context: context
          end

          wait_for do
            @event = AuditTrail::Event.find_by name: "another_event"
          end
          expect(@event.context.name).to eq "some_event"
        end

        it "records a hierarchy of events" do
          AuditTrail.service.record "parent" do |parent|
            AuditTrail.service.record "child", context: parent do |child|
              AuditTrail.service.record "grandchild", context: child
            end
          end

          wait_for { @event = AuditTrail::Event.find_by name: "grandchild" }
          expect(@event.context.name).to eq "child"
          expect(@event.context.context.name).to eq "parent"
        end
      end

      context "#status" do
        it "marks the event as in progress" do
          AuditTrail.service.record "some_event" do |context|
            expect { context.reload.in_progress? }.to become_true
          end
        end

        it "marks the event as completed" do
          AuditTrail.service.record "some_event"

          wait_for { @event = AuditTrail::Event.find_by name: "some_event" }
          expect { @event.reload.completed? }.to become_true
        end

        it "marks the event as failed" do
          AuditTrail.service.record "some_event" do
            raise "BOOM"
          end

          wait_for { @event = AuditTrail::Event.find_by name: "some_event" }
          expect { @event.reload.failed? }.to become_true
        end
      end

      context "#result" do
        it "records the result of the event as a simple type" do
          AuditTrail.service.record "some_event", result: :the_result

          wait_for { @event = AuditTrail::Event.find_by name: "some_event" }
          expect { @event.reload.result }.to become :the_result
        end

        it "records the result of the event as a linked model" do
          @some_user = User.create! name: "Some person"

          AuditTrail.service.record "some_event", result: @some_user

          wait_for { @event = AuditTrail::Event.find_by name: "some_event" }
          expect { @event.reload.result }.to become @some_user
        end
      end

      context "#exception" do
        it "records the exception that caused the failure" do
          AuditTrail.service.record "some_event" do
            raise "BOOM"
          end

          wait_for { @event = AuditTrail::Event.find_by name: "some_event" }
          expect { @event.reload.exception_class }.to become "RuntimeError"
          expect { @event.reload.exception_message }.to become "BOOM"
        end
      end

      context "inheritance" do
        it "inherits the user from the current context" do
          @user = User.create! name: "Some person"
          @other_user = User.create! name: "Someone else"

          AuditTrail.service.record "some_event", user: @user do |context|
            AuditTrail.service.record "another_event", context: context
          end

          wait_for { @event = AuditTrail::Event.find_by name: "another_event" }
          expect(@event.user).to eq @user
        end

        it "overrides the user from the current context" do
          @user = User.create! name: "Some person"
          @other_user = User.create! name: "Someone else"

          AuditTrail.service.record "some_event", user: @user do |context|
            AuditTrail.service.record "another_event", user: @other_user, context: context
          end

          wait_for { @event = AuditTrail::Event.find_by name: "another_event" }
          expect(@event.user).to eq @other_user
        end
      end
    end
  end
end
