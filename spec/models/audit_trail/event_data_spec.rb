require "rails_helper"

RSpec.describe AuditTrail::EventData do
  it "reads values from the associated event" do
    @event = AuditTrail::Event.new name: "whatever", internal_data: {string: "Hello", number: 123}

    @event_data = described_class.new @event

    expect(@event_data[:string]).to eq "Hello"
    expect(@event_data[:number]).to eq 123
  end

  it "reads models from the event's linked models" do
    @user = User.create! name: "Someone"
    @event = AuditTrail::Event.create! name: "whatever", internal_data: {string: "Hello", number: 123}
    @event.links.create name: "owner", model: @user

    @event_data = described_class.new @event

    expect(@event_data[:owner]).to eq @user
  end

  it "writes values to the associated event" do
    @event = AuditTrail::Event.new name: "whatever", internal_data: {string: "Hello", number: 123}

    @event_data = described_class.new @event

    @event_data[:string] = "Goodbye"
    @event_data[:something] = "else"

    expect(@event.internal_data[:string]).to eq "Goodbye"
    expect(@event.internal_data[:something]).to eq "else"
  end

  it "writes values to the event's linked models" do
    @user = User.create! name: "Someone"
    @another_user = User.create! name: "Someone else"
    @post = Post.create! user: @user, title: "Something", contents: "Blah blah blah"
    @event = AuditTrail::Event.create! name: "whatever", internal_data: {string: "Hello", number: 123}
    @event.links.create! name: "author", model: @user

    @event_data = described_class.new @event

    @event_data[:post] = @post
    @event_data[:author] = @another_user

    expect(@event.links.find_by(name: "post").model).to eq @post
    expect(@event.links.where(name: "author").count).to eq 1
    expect(@event.links.find_by(name: "author").model).to eq @another_user
  end

  it "applies a load of data in one go" do
    @user = User.create! name: "Someone"
    @event = AuditTrail::Event.create! name: "whatever"

    @event_data = described_class.new @event
    @event_data.apply author: @user, text: "Hello"

    expect(@event_data[:text]).to eq "Hello"
    expect(@event_data[:author]).to eq @user

  end
end
