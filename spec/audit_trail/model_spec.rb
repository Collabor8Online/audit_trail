require "rails_helper"

RSpec.describe AuditTrail::Model do
  Plumbing::Spec.modes do
    context "In #{Plumbing.config.mode} mode" do
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

          expect { @post.reload.linked_events.include? @first_event }.to become_true
          expect { @post.reload.linked_events.include? @second_event }.to become_true
        end
      end
    end
  end
end
