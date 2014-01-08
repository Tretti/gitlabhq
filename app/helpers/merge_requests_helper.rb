module MergeRequestsHelper
  def new_mr_path_from_push_event(event)
    target_project = event.project.forked_from_project || event.project
    new_project_merge_request_path(
      event.project,
      new_mr_from_push_event(event, target_project)
    )
  end

  def new_mr_path_for_fork_from_push_event(event)
    new_project_merge_request_path(
      event.project,
      new_mr_from_push_event(event, event.project.forked_from_project)
    )
  end

  def new_mr_from_push_event(event, target_project)
    merge_request = MergeRequest.new(
      source_branch: event.branch_name,
      target_branch: target_project.repository.root_ref,
      source_project_id: event.project.id,
      target_project_id: target_project.id
    )
    merge_request.author = event.author

    title, description = title_and_description(merge_request)

    return :merge_request => {
      source_project_id: event.project.id,
      target_project_id: target_project.id,
      source_branch: event.branch_name,
      target_branch: target_project.repository.root_ref,
      title: title,
      description: description,
    }
  end

  def mr_css_classes mr
    classes = "merge-request"
    classes << " closed" if mr.closed?
    classes << " merged" if mr.merged?
    classes
  end

  def ci_build_details_path merge_request
    merge_request.source_project.gitlab_ci_service.build_page(merge_request.last_commit.sha)
  end

  def merge_path_description(merge_request, separator)
    if merge_request.for_fork?
      "Project:Branches: #{@merge_request.source_project.path_with_namespace}:#{@merge_request.source_branch} #{separator} #{@merge_request.target_project.path_with_namespace}:#{@merge_request.target_branch}"
    else
      "Branches: #{@merge_request.source_branch} #{separator} #{@merge_request.target_branch}"
    end
  end

private

  def title_and_description (merge_request)
    source_branch = merge_request.source_branch
    source_repository = merge_request.source_project.repository
    source_commit = source_repository.commit(source_branch) if source_branch.present?

    target_repository = merge_request.target_project.repository
    target_commit = target_repository.commit(merge_request.target_branch) if merge_request.target_branch.present?

    if source_commit && target_commit
      merge_request.reload_code if merge_request.commits.blank?

      if merge_request.commits.length == 1
        description = source_commit.description.try(:strip)
        title = source_commit.title
      end
    end

    title = source_branch.titleize if title.blank?

    return title, description
  end
end
