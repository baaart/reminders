class ProjectsRepository
  def all
    Project.all
  end

  def find(project_id)
    Project.find_by(id: project_id)
  end

  def with_done_checks
    Project.includes(checked_reviews: [:reminder, :last_check_user])
  end

  def persist(entity)
    entity.save
  end

  def for_reminder(reminder)
    reminder.projects
  end

  delegate :find_by_name, to: :all
end
