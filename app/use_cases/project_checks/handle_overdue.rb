module ProjectChecks
  class HandleOverdue
    attr_accessor :check, :days_diff, :notifier

    def initialize(check, days_diff, notifier = nil)
      self.check = check
      self.days_diff = days_diff
      self.notifier = notifier || Notifier.new
    end

    def call
      notify!
    end

    private

    def notify!
      notifier.send_message notification, channel: "##{project.channel_name}"
    end

    def reminder
      check.reminder
    end

    def project
      check.project
    end

    def notification
      Liquid::Template.parse(notification_template)
        .render(available_variables)
    end

    def notification_template
      reminder.deadline_text
    end

    def available_variables
      {
        reminder_name: reminder.name,
        project_name: project.name,
        days_ago: days_diff,
        valid_for: reminder.valid_for_n_days,
      }.stringify_keys
    end
  end
end
