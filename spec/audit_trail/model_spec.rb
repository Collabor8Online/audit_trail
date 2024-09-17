require "rails_helper"

RSpec.describe AuditTrail::Model do
  context "#linked_events" do
    it "lists events that it is involved in" do
      Post.class_eval do
        include AuditTrail::Model
      end
      @user = User.create! name: "Someone"
      @post = Post.create user: @user, title: "Something"

      await do
        AuditTrail.service.record "first_event", user: @user, post: @post do
          AuditTrail.service.record "second_event", post: @post
        end
      end

      @first_event = AuditTrail::Event.find_by name: "first_event"
      @second_event = AuditTrail::Event.find_by name: "second_event"

      expect(@post.linked_events).to include @first_event
      expect(@post.linked_events).to include @second_event
    end
  end
end
