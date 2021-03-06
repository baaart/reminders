class ProjectChecksController < ApplicationController
  before_action :authenticate_admin!,
                only: [:override_deadline, :toggle_state]

  expose(:project_checks_repository) { ProjectChecksRepository.new }
  expose(:check) do
    project_checks_repository.find(
      params[:id] || params[:project_check_id],
    )
  end
  expose(:reminders_repository) { RemindersRepository.new }
  expose(:reminder) do
    reminders_repository.find(params[:reminder_id])
  end
  expose(:users) { UsersWithSkillRepository.new(reminder).active }
  expose(:assignments_repo) { CheckAssignmentsRepository.new }
  expose(:users_repo) { UsersRepository.new }

  def pick_person
    last_checker = assignments_repo.latest_assignment(check).try(:user)
    self.reminder = check.reminder
    user_assigner = UserAssigner.new(reminder, users, last_checker)
    self.users = UserAssignerResultDecorator.decorate_collection(
      user_assigner.results)
  end

  def reassign_person
    latest_assignment = assignments_repo.latest_assignment(check)
    notice = CheckAssignments::Cancel.new(latest_assignment).call
    redirect_to project_check_pick_person_path(check),
                notice: notice
  end

  def assign_checker
    notice = CheckAssignments::AssignPerson.new(
      project_check: check,
      assignments_repo: assignments_repo,
      person: users_repo.find(params[:user_id]),
      contact_person: current_user,
    ).call
    redirect_to reminder_path(check.reminder),
                notice: notice
  end

  # rubocop:disable Metrics/AbcSize
  def toggle_state
    check.enabled = !check.enabled
    redirect_path = request.referrer || reminder_path(check.reminder)
    if check.save
      redirect_to redirect_path, notice: "All right!"
    else
      redirect_to redirect_path,
                  alert: check.errors.full_messages.join(", ")
    end
  end
  # rubocop:enable Metrics/AbcSize

  def override_deadline
    redirect_args = if override_deadline_call
                      { notice: "All right! Initial due date changed!" }
                    else
                      { alert: check.errors.full_messages.join(", ") }
                    end
    redirect_to reminder_path(check.reminder), redirect_args
  end

  def update
    if ProjectChecks::Update.new(check: check).call(check_params)
      redirect_to check.reminder, notice: "Check info updated."
    else
      flash.now[:alert] = check.errors.full_messages.join(", ")
      render :edit
    end
  end

  private

  def check_params
    params.require(:project_check).permit(:info)
  end

  def override_deadline_call
    ProjectChecks::OverrideDeadline.new(
      check: check,
      project_checks_repository: project_checks_repository,
      new_days_left: params[:project_check_days_left],
    ).call
  end
end
