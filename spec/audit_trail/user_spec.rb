require "rails_helper"

RSpec.describe AuditTrail::User do
  Plumbing::Spec.modes do
    context "In #{Plumbing.config.mode} mode" do
      context "#events" do
        it "lists events that this user has performed" do
          User.class_eval do
            include AuditTrail::User
          end

          @user = User.create! name: "Someone"

          AuditTrail.service.record "first_event", user: @user do |context|
            AuditTrail.service.record "second_event", context: context
          end

          wait_for { @first_event = AuditTrail::Event.find_by name: "first_event" }
          wait_for { @second_event = AuditTrail::Event.find_by name: "second_event" }

          expect { @user.events.include? @first_event }.to become_true
          expect { @user.events.include? @second_event }.to become_true
        end
      end
    end
  end
end
