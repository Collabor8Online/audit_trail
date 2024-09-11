require "rails_helper"

RSpec.describe "Recording single audit trail events" do
  it "records the event name" do
    AuditTrail.record "some_event"

    @event = AuditTrail::Event.last
    expect(@event.name).to eq "some_event"
  end

  it "records a partition key" do
    AuditTrail.record "some_event", partition: "partition-123"

    @event = AuditTrail::Event.last
    expect(@event.partition).to eq "partition-123"
  end

  it "records the user" do
    @user = User.create! name: "Some person"

    AuditTrail.record "some_event", user: @user

    @event = AuditTrail::Event.last
    expect(@event.user).to eq @user
  end

  it "records parameters with the event" do
    AuditTrail.record "some_event", string: "Hello", number: 123

    @event = AuditTrail::Event.last
    expect(@event.data).to eq({string: "Hello", number: 123})
  end

  it "records models with the event" do
    @user = User.create! name: "Some person"
    @post = Post.create! user: @user, title: "Hello world", contents: "Welcome to my blog!"

    AuditTrail.record "post_added", post: @post, title: "Hello world"

    @event = AuditTrail::Event.last
    expect(@event.data).to eq({title: "Hello world"})
    expect(@event.links.find_by(model: @post)).to_not be_nil
  end

  it "records the partition key along with models and the event" do
    @user = User.create! name: "Some person"
    @post = Post.create! user: @user, title: "Hello world", contents: "Welcome to my blog!"

    AuditTrail.record "post_added", post: @post, title: "Hello world", partition: "partition-123"

    @event = AuditTrail::Event.last
    expect(@event.data).to eq({title: "Hello world"})
    expect(@event.links.find_by(model: @post).partition).to eq "partition-123"
  end

  it "records the parent event as the context for this event" do
    @context = AuditTrail::Event.create! name: "parent", status: "completed"

    AuditTrail.record "child", context: @context

    @event = AuditTrail::Event.last
    expect(@event.context).to eq @context
    expect(@context.children).to include @event
  end

  it "records that the event has completed" do
    AuditTrail.record "some_event"

    @event = AuditTrail::Event.last
    expect(@event).to be_completed
  end
end
