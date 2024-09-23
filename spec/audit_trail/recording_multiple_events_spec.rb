require "rails_helper"

RSpec.describe "Recording audit trail events within the context of other events" do
  Plumbing::Spec.modes do
    context "in #{Plumbing.config.mode} mode" do
      context "context" do
        it "records an event within the context of another event" do
          AuditTrail.service.record "some_event" do
            AuditTrail.service.record "another_event"
          end

          wait_for do
            @event = AuditTrail::Event.find_by name: "another_event"
          end
          expect(@event.context.name).to eq "some_event"
        end

        it "records a hierarchy of events" do
          AuditTrail.service.record "parent" do
            AuditTrail.service.record "child" do
              AuditTrail.service.record "grandchild"
            end
          end

          wait_for { @event = AuditTrail::Event.find_by name: "grandchild" }
          expect(@event.context.name).to eq "child"
          expect(@event.context.context.name).to eq "parent"
        end
      end

      context "#status" do
        it "marks the event as in progress" do
          AuditTrail.service.record "some_event" do
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

          AuditTrail.service.record "some_event", user: @user do
            AuditTrail.service.record "another_event"
          end

          wait_for { @event = AuditTrail::Event.find_by name: "another_event" }
          expect(@event.user).to eq @user
        end

        it "overrides the user from the current context" do
          @user = User.create! name: "Some person"
          @other_user = User.create! name: "Someone else"

          AuditTrail.service.record "some_event", user: @user do
            AuditTrail.service.record "another_event", user: @other_user
          end

          wait_for { @event = AuditTrail::Event.find_by name: "another_event" }
          expect(@event.user).to eq @other_user
        end

        it "knows the current context" do
          AuditTrail.service.record "parent" do
            AuditTrail.service.record "child" do
              @context = await { AuditTrail.service.current_context }
            end
          end

          wait_for { @event = AuditTrail::Event.find_by name: "child" }

          expect(@context).to eq @event
        end

        it "knows the current user" do
          @alice = User.create! name: "Alice"

          AuditTrail.service.record "parent", user: @alice do
            @parent_user = await { AuditTrail.service.current_user }
            AuditTrail.service.record "child" do
              @child_user = await { AuditTrail.service.current_user }
            end
          end

          wait_for { @event = AuditTrail::Event.find_by name: "child" }

          expect(@parent_user).to eq @alice
          expect(@child_user).to eq @alice
        end

        it "sets the current context" do
          @alice = User.create! name: "Alice"

          @event = await { AuditTrail.service.record "parent", user: @alice }

          AuditTrail.service.in_context(@event) do
            AuditTrail.service.record "child" do
              @bob = User.create! name: "Bob"
              AuditTrail.service.record "grandchild", user: @bob
            end
          end

          wait_for { @child_event = AuditTrail::Event.find_by name: "child" }
          expect(@child_event.context).to eq @event
          expect(@child_event.user).to eq @alice

          wait_for { @grandchild_event = AuditTrail::Event.find_by name: "grandchild" }
          expect(@grandchild_event.context).to eq @child_event
          expect(@grandchild_event.user.name).to eq "Bob"
        end
      end
    end
  end
end
