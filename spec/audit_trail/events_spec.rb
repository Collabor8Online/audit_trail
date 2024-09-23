require "rails_helper"

RSpec.describe "AuditTrail.events" do
  Plumbing::Spec.modes do
    context "In #{Plumbing.config.mode} mode" do
      it "publishes events when they are started" do
        @result = []
        @events = []

        AuditTrail.events.add_observer do |name, data|
          @result << name
          @events << data[:event]
        end

        AuditTrail.service.record "some_event"

        expect { @result.include? "some_event:in_progress" }.to become_true
        expect(@events.first.name).to eq "some_event"
      end

      it "publishes events when they are completed" do
        @result = []
        @events = []

        AuditTrail.events.add_observer do |name, data|
          @result << name
          @events << data[:event]
        end

        AuditTrail.service.record "some_event"

        expect { @result.include? "some_event:completed" }.to become_true
        expect(@events.last.name).to eq "some_event"
      end

      it "publishes events when they fail" do
        @result = []
        @events = []

        AuditTrail.events.add_observer do |name, data|
          @result << name
          @events << data[:event]
        end

        AuditTrail.service.record "some_event" do
          raise "BOOM"
        end
        expect { @result.include? "some_event:failed" }.to become_true
        expect(@events.last.name).to eq "some_event"
      end
    end
  end
end
