require "rails_helper"

RSpec.describe "Recording audit trail events in stages" do
  context "#start" do
    it "records the start of an event" do
      @user = User.create! name: "Alice"
      @post = Post.create! user: @user, title: "Hello world"

      AuditTrail.service.start "some_event", user: @user, description: "A new post", post: @post

      @event = AuditTrail::Event.last
      expect(@event.name).to eq "another_event"
      expect(@event.user).to eq @user
      expect(@event.data[:description]).to eq "A new post"
      expect(@event.data[:post]).to eq @post

      expect(AuditTrail.current_context).to eq @event
    end
    it "records the start of an event in the context of another event"
  end

  context "#complete" do
    it "records the end of an event with a simple result"
    it "records the end of an event with a model result"
    it "returns to the previous context"
  end

  context "#failure" do
    it "records that an event failed"
    it "returns to the previous context"
  end
end
