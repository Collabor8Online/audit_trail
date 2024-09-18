require "rails_helper"

RSpec.describe AuditTrail::Model do
  context "#linked_events" do
    it "lists events that it is involved in" do
      Post.class_eval do
        include AuditTrail::Model
      end
      @user = User.create! name: "Someone"
      @post = Post.create user: @user, title: "Something"

      AuditTrail.service.record "first_event", user: @user, post: @post do
        AuditTrail.service.record "second_event", post: @post
      end

      wait_for { @first_event = AuditTrail::Event.find_by name: "first_event" }
      wait_for { @second_event = AuditTrail::Event.find_by name: "second_event" }

      expect(true).to become_equal_to { @post.reload.linked_events.include? @first_event }
      expect(true).to become_equal_to { @post.reload.linked_events.include? @second_event }
    end
  end
end
