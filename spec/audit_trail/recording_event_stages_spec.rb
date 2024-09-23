require "rails_helper"

RSpec.describe "Recording audit trail events in stages" do
  Plumbing::Spec.modes do
    context "In #{Plumbing.config.mode} mode" do
      context "#start" do
        it "records the start of an event" do
          @user = User.create! name: "Alice"
          @post = Post.create! user: @user, title: "Hello world"

          AuditTrail.service.start "some_event", user: @user, description: "A new post", post: @post

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
          @event = await { AuditTrail.service.start "some_event", description: "A new post" }

          AuditTrail.service.complete @event, result: "DONE"

          expect { @event.reload.result }.to become "DONE"
        end

        it "records the end of an event with a model result" do
          @user = User.create! name: "Alice"
          @event = await { AuditTrail.service.start "some_event", description: "A new post" }

          AuditTrail.service.complete @event, result: @user

          expect { @event.reload.result }.to become @user
        end
      end

      context "#fail" do
        it "records that an event failed" do
          @event = await { AuditTrail.service.start "some_event", description: "A new post" }

          AuditTrail.service.fail @event, RuntimeError.new("FAIL")

          expect { @event.reload.exception_class }.to become "RuntimeError"
          expect { @event.reload.exception_message }.to become "FAIL"
        end
      end
    end
  end
end
