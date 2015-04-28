require "spec_helper"

describe ProjectChecks::HandleNotificationDay do
  let(:service) {  described_class.new(check, days_diff, notifier) }
  let(:days_diff) { 10 }
  let(:project) do
    double(:project, name: "foo project", channel_name: "foo-project")
  end
  let(:notification_text) { "foo bar baz" }
  let(:reminder) do
    double(:reminder, name: "bar baz", valid_for_n_days: 5,
                      notification_text: notification_text)
  end
  let(:check) { double(:project_check, reminder: reminder, project: project) }
  let(:notifier) { double(:notifier, send_message: true) }

  describe "#call" do
    it "passes message to notifier" do
      expect(notifier).to receive(:send_message)
        .with(notification_text, channel: "#foo-project")
      service.call
    end

    context "passing variables works correctly for" do
      after do
        service.call
      end

      it "days_ago" do
        expect(reminder).to receive(:notification_text)
          .and_return("{{ days_ago }} days ago")

        expect(notifier).to receive(:send_message)
          .with("10 days ago", anything)
      end

      it "project_name" do
        expect(reminder).to receive(:notification_text)
          .and_return("project {{ project_name }}")

        expect(notifier).to receive(:send_message)
          .with("project foo project", anything)
      end

      it "reminder_name" do
        expect(reminder).to receive(:notification_text)
          .and_return("{{ reminder_name }} reminder")

        expect(notifier).to receive(:send_message)
          .with("bar baz reminder", anything)
      end

      it "valid_for" do
        expect(reminder).to receive(:notification_text)
          .and_return("is valid for {{ valid_for }} days")

        expect(notifier).to receive(:send_message)
          .with("is valid for 5 days", anything)
      end
    end
  end
end
