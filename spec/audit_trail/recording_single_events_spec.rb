require "rails_helper"

RSpec.describe "Recording single audit trail events" do
  Plumbing::Spec.modes do
    context "In #{Plumbing.config.mode} mode" do
      it "records the event name" do
        await { AuditTrail.service.record "some_event" }

        @event = AuditTrail::Event.last
        expect(@event.name).to eq "some_event"
      end

      it "records the user" do
        @user = User.create! name: "Some person"

        await { AuditTrail.service.record "some_event", user: @user }

        @event = AuditTrail::Event.last
        expect(@event.user).to eq @user
      end

      it "records parameters with the event" do
        await { AuditTrail.service.record "some_event", string: "Hello", number: 123 }

        @event = AuditTrail::Event.last
        expect(@event.data[:string]).to eq "Hello"
        expect(@event.data[:number]).to eq 123
      end

      it "records models with the event" do
        @user = User.create! name: "Some person"
        @post = Post.create! user: @user, title: "Hello world", contents: "Welcome to my blog!"

        await { AuditTrail.service.record "post_added", post: @post, title: "Hello world" }

        @event = AuditTrail::Event.last
        expect(@event.data[:title]).to eq "Hello world"
        expect(@event.links.find_by(model: @post)).to_not be_nil
      end

      it "records the parent event as the context for this event" do
        @context = AuditTrail::Event.create! name: "parent", status: "completed"

        await { AuditTrail.service.record "child", context: @context }

        @event = AuditTrail::Event.last
        expect(@event.context).to eq @context
        expect(@context.children).to include @event
      end

      it "records that the event has completed" do
        await { AuditTrail.service.record "some_event" }

        @event = AuditTrail::Event.last
        expect(@event).to be_completed
      end
    end
  end
end
