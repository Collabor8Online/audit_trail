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

      context ".event_names" do
        it "lists the names of the events that this model will broadcast" do
          Post.class_eval do
            include AuditTrail::Model
            broadcasts_events :published, :updated, :deleted
          end

          expect(Post.event_names).to include :published
          expect(Post.event_names).to include :updated
          expect(Post.event_names).to include :deleted
        end
      end
    end
  end
end
