require "rails_helper"

RSpec.describe "AuditTrail.events" do
  [:inline, :threaded_rails].each do |mode|
    context "In #{mode} mode" do
      around :each do |example|
        Plumbing.configure mode: mode, timeout: 3, debug: false, &example
      end
      it "publishes events when they are started" do
        @result = []
        AuditTrail.events.add_observer do |notification|
          @result << notification.type
        end

        AuditTrail.service.record "some_event"

        expect { @result.include? "some_event:in_progress" }.to become_true
      end

      it "publishes events when they are completed" do
        @result = []
        AuditTrail.events.add_observer do |notification|
          @result << notification.type
        end

        AuditTrail.service.record "some_event"

        expect { @result.include? "some_event:completed" }.to become_true
      end

      it "publishes events when they fail" do
        @result = []
        AuditTrail.events.add_observer do |notification|
          @result << notification.type
        end

        AuditTrail.service.record "some_event" do
          raise "BOOM"
        end
        expect { @result.include? "some_event:failed" }.to become_true
      end
    end
  end
end
