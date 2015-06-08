module CheckAssignments
  class Complete
    attr_reader :assignments_repository, :assignment,
                :checker, :project_check_update
    private :assignments_repository, :assignment,
            :checker, :project_check_update

    def initialize(args)
      @assignment = args.fetch(:assignment)
      @checker = args.fetch(:checker)
      @assignments_repository = CheckAssignmentsRepository.new
      @project_check_update =
        ProjectChecks::Update.new(check: assignment.project_check)
    end

    def call
      complete_assignment
    end

    private

    def complete_assignment
      assignments_repository.update(
        assignment,
        completion_date: Time.now, user_id: checker.id,
      )
      project_check_update.call(
        last_check_date: assignment.completion_date,
        last_check_user_id: checker.id,
      )
    end
  end
end
