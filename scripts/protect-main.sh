#!/usr/bin/env bash
# Creates (or updates) the "Protect main" branch ruleset on every Osun EduOS repository.
# Needs the GitHub CLI signed in as an organisation admin: gh auth status
#
# Rules on the default branch:
#   - changes arrive by pull request: 1 approval, code owner review, stale approvals dismissed,
#     conversations resolved, squash merge only
#   - required CI checks must pass (per repository, below)
#   - linear history; no force pushes; the branch cannot be deleted
#   - organisation and repository admins can bypass (remove once there is a second maintainer)
set -euo pipefail

ORG=Osun-eduos
NAME="Protect main"
ACTIONS_APP_ID=15368 # GitHub Actions, so a check is only accepted from CI

# repository:required check names (job names in .github/workflows/ci.yml)
REPOS=(
  "eduos-api:test"
  "eduos-web:build"
  "eduos-mobile:test"
  "eduos-sync:test"
  "osun-eduos:"
)

echo "Signed in as $(gh api user -q .login)"

for entry in "${REPOS[@]}"; do
  repo=${entry%%:*}
  checks=${entry#*:}

  rules='[
    {"type":"deletion"},
    {"type":"non_fast_forward"},
    {"type":"required_linear_history"},
    {"type":"pull_request","parameters":{
      "required_approving_review_count":1,
      "dismiss_stale_reviews_on_push":true,
      "require_code_owner_review":true,
      "require_last_push_approval":false,
      "required_review_thread_resolution":true,
      "allowed_merge_methods":["squash"]}}'
  if [ -n "$checks" ]; then
    list=""
    for c in ${checks//,/ }; do
      list+="${list:+,}{\"context\":\"$c\",\"integration_id\":$ACTIONS_APP_ID}"
    done
    rules+=',{"type":"required_status_checks","parameters":{
      "strict_required_status_checks_policy":false,
      "do_not_enforce_on_create":false,
      "required_status_checks":['"$list"']}}'
  fi
  rules+=']'

  body=$(cat <<JSON
{
  "name": "$NAME",
  "target": "branch",
  "enforcement": "active",
  "bypass_actors": [
    {"actor_id": 1, "actor_type": "OrganizationAdmin", "bypass_mode": "always"},
    {"actor_id": 5, "actor_type": "RepositoryRole", "bypass_mode": "always"}
  ],
  "conditions": {"ref_name": {"include": ["~DEFAULT_BRANCH"], "exclude": []}},
  "rules": $rules
}
JSON
)

  id=$(gh api "repos/$ORG/$repo/rulesets" -q ".[] | select(.name == \"$NAME\") | .id" | head -1)
  if [ -n "$id" ]; then
    echo "$body" | gh api -X PUT "repos/$ORG/$repo/rulesets/$id" --input - -q '"\(.name) updated on '"$repo"' (id \(.id))"'
  else
    echo "$body" | gh api -X POST "repos/$ORG/$repo/rulesets" --input - -q '"\(.name) created on '"$repo"' (id \(.id))"'
  fi
done
