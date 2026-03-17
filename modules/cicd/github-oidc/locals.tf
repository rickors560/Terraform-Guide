locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Team        = var.team
      CostCenter  = var.cost_center
      Repository  = var.repository
    },
    var.additional_tags,
  )

  github_oidc_url = "https://token.actions.githubusercontent.com"

  # Build the list of allowed sub claims from repositories and branches
  allowed_subjects = flatten([
    for repo in var.github_repositories : [
      for ref in repo.branches : "repo:${repo.owner}/${repo.name}:ref:refs/heads/${ref}"
    ]
  ])

  # Add environment-based subjects
  allowed_environment_subjects = flatten([
    for repo in var.github_repositories : [
      for env in repo.environments : "repo:${repo.owner}/${repo.name}:environment:${env}"
    ]
  ])

  # Add pull request subjects
  allowed_pr_subjects = [
    for repo in var.github_repositories : "repo:${repo.owner}/${repo.name}:pull_request"
    if repo.allow_pull_requests
  ]

  # Add tag-based subjects
  allowed_tag_subjects = flatten([
    for repo in var.github_repositories : [
      for tag in repo.tags : "repo:${repo.owner}/${repo.name}:ref:refs/tags/${tag}"
    ]
  ])

  all_allowed_subjects = concat(
    local.allowed_subjects,
    local.allowed_environment_subjects,
    local.allowed_pr_subjects,
    local.allowed_tag_subjects,
  )
}
