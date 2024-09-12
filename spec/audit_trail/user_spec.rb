require "rails_helper"

RSpec.describe AuditTrail::User do
  context "#events" do
    it "lists events that this user has performed" do
      User.class_eval do
        include AuditTrail::User
      end

      @user = User.create! name: "Someone"
      AuditTrail.record "first_event", user: @user do
        AuditTrail.record "second_event"
      end
      @first_event = AuditTrail::Event.find_by name: "first_event"
      @second_event = AuditTrail::Event.find_by name: "second_event"

      expect(@user.events).to include @first_event
      expect(@user.events).to include @second_event
    end
  end
end
