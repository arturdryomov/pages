---
title: "Autonomous GitHub Pull Requests"
description: "Less actions via more Actions"
date: 2021-03-08
slug: auto-github-pull-requests
---

In general, people are lazy. This is our nature — we want to achieve more by doing less.
Developers are on the next step of this urge — we want to automate similar actions,
patterns in human behavior. And what’s more repetitive than working on pull requests
for each source code change we make?

# Workflow

Over time and multiple iterations I’ve established the following workflow.

1. Open a PR.
    * Assign reviewers automatically.
1. Refine the PR.
    * Run automatic checks (compiler, tests, linters):
        * on success — attempt automatic merge;
        * on failure — push new changes.
    * Receive reviews:
        * on approve — attempt automatic merge;
        * on decline — push new changes.
1. Merge the PR.
    * Update PRs targeting the same branch.

This approach reduces the manual interaction as much as possible.
Developers provide changes and reviews, the automation handles everything else.
There is no need to choose people for review, track checks and review statuses,
merge and update remaining PRs.

> :book: The [How the Pull Request is Built]({{< relref "2018-07-29-pull-request.md" >}}) article
> explains the importance of keeping pull request branches up to date with the target one.

The workflow can be brought to life via GitHub and GitHub Actions with a bit of help
from [`curl`](https://curl.se/) and [`jq`](https://stedolan.github.io/jq/).

# Implementation

> :triangular_flag_on_post: This article is not a tutorial for GitHub Actions.
> GitHub [has a great one](https://docs.github.com/en/actions/learn-github-actions).

## Assign Reviewers

Can be achieved via [code owners](https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/about-code-owners)
and [teams](https://docs.github.com/en/github/setting-up-and-managing-organizations-and-teams/organizing-members-into-teams).

1. [Create a GitHub team](https://docs.github.com/en/github/setting-up-and-managing-organizations-and-teams/creating-a-team).
1. Create a GitHub `CODEOWNERS` file.
    ```console
    $ cat .github/CODEOWNERS

    # Makes the team owners of everything but this can be fine-tuned (see the documentation)
    * @REPLACE_WITH_ORG_NAME/REPLACE_WITH_TEAM_NAME
    ```
1. Configure [code review assignment](https://docs.github.com/en/github/setting-up-and-managing-organizations-and-teams/managing-code-review-assignment-for-your-team) for the GitHub team.

That’s it! On opening a PR GitHub will add the team as reviewers (thanks to `CODEOWNERS`)
and immediately will replace it with individual team members according to chosen
rules (thanks to the code review assignment).

Since both team members and review assignments are configured via the UI,
it’s possible to adjust conditions without making changes in the source code.
This can be useful when developers go on vacation or switch teams.

## Cancel Runs

This is not mentioned in the workflow above but it’s important nevertheless.
ATM GitHub doesn’t touch existing workflow runs on new runs of the same workflow.
For example:

1. a PR is opened with commits `A`, `B`, `C`;
1. GitHub starts a workflow run for commit `C`;
1. immediately after opening a PR developer notices a typo and pushes commit `D`;
1. GitHub starts a workflow run for commit `D`;
1. GitHub executes runs for commits `C` in `D` in parallel.

This makes total sense but is impractical from a PR-based perspective.
The PR should be checked using the final state, not intermediate ones.
At the same time, more runs mean more used resources.

Both [Bitrise](https://devcenter.bitrise.io/builds/rolling-builds/)
and [CircleCI](https://circleci.com/docs/2.0/skip-build/#auto-cancelling-a-redundant-build)
have the redundant runs cancellation option.
GitHub Actions doesn’t but it can be done via
[the GitHub Actions API](https://docs.github.com/en/rest/reference/actions):


1. [find a workflow of the current run](https://docs.github.com/en/rest/reference/actions#get-a-workflow-run);
1. [find runs of the workflow](https://docs.github.com/en/rest/reference/actions#list-workflow-runs);
1. [cancel runs of the workflow except the current run](https://docs.github.com/en/rest/reference/actions#cancel-a-workflow-run).

The following script does that.

<details>
  <summary><code>.github/workflows/pull-request-cancel-concurrent.sh</code></summary>

```bash
#!/bin/bash
set -eou pipefail

GITHUB_TOKEN="${1}"

curl \
  --fail \
  --silent \
  --show-error \
  --request "GET" \
  --url "${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}" \
  --header "Authorization: token ${GITHUB_TOKEN}" \
  --output "run.json"

WORKFLOW_ID=$(jq ".workflow_id" run.json)

curl \
  --fail \
  --silent \
  --show-error \
  --request "GET" \
  --url "${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/actions/workflows/${WORKFLOW_ID}/runs?branch=${GITHUB_HEAD_REF}&status=queued&status=in_progress" \
  --header "Authorization: token ${GITHUB_TOKEN}" \
  --output "runs.json"

for WORKFLOW_RUN_ID in $(jq ".workflow_runs[] | .id" runs.json); do

  if [ "${WORKFLOW_RUN_ID}" != "${GITHUB_RUN_ID}" ]; then
    echo ":: Cancelling workflow run #${WORKFLOW_RUN_ID}..."
    curl \
      --silent \
      --show-error \
      --request "POST" \
      --url "${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/actions/runs/${WORKFLOW_RUN_ID}/cancel" \
      --header "Authorization: token ${GITHUB_TOKEN}"
  fi

done
```

</details>

The script should be called from a PR workflow.

```yaml
on:
  pull_request:

jobs:
  pull-request-cancel-concurrent:
    runs-on: "ubuntu-latest"

    steps:
    - name: "Checkout the source code"
      uses: actions/checkout@v2

    - name: "Cancel concurrent runs"
      run: bash .github/workflows/pull-request-cancel-concurrent.sh "${{ secrets.GITHUB_TOKEN }}"
```

> :book: The script uses
> [the GitHub-provided authentication token](https://docs.github.com/en/actions/reference/authentication-in-a-workflow)
> via `secrets.GITHUB_TOKEN` and a good amount of GitHub-provided
> [environment variables](https://docs.github.com/en/actions/reference/environment-variables#default-environment-variables).

## Merge and Update

> :eight_spoked_asterisk: GitHub has a feature called
> [Auto-Merge](https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/automatically-merging-a-pull-request)
> but its automation part is... partial. It requires using a dedicated button
> for each opened PR making it easy to forget or even miss.

Merging itself is straightforward —
it’s [a single API call](https://docs.github.com/en/rest/reference/pulls#merge-a-pull-request).

<details>
  <summary><code>.github/workflows/pull-request-merge.sh</code></summary>

```bash
#!/bin/bash
set -eou pipefail

GITHUB_TOKEN="${1}"
GITHUB_PR_NUMBER="${2}"
GITHUB_PR_TITLE="${3}"

curl \
  --fail \
  --silent \
  --show-error \
  --request "PUT" \
  --url "${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/pulls/${GITHUB_PR_NUMBER}/merge" \
  --header "Authorization: token ${GITHUB_TOKEN}" \
  --header "Content-Type: application/json" \
  --data "{
    \"merge_method\": \"squash\",
    \"commit_title\": \"${GITHUB_PR_TITLE}\",
    \"commit_message\": \"\"
  }"
```
</details>

Updating is a bit more interesting and consists of multiple steps:

1. find the current PR target branch;
1. [find PRs with the same target branch](https://docs.github.com/en/rest/reference/pulls#list-pull-requests);
1. [update found PRs](https://docs.github.com/en/rest/reference/pulls#update-a-pull-request-branch).

<details>
  <summary><code>.github/workflows/pull-request-update.sh</code></summary>

```bash
#!/bin/bash
set -eou pipefail

GITHUB_TOKEN="${1}"
GITHUB_TOKEN_USER="${2}"

curl \
  --fail \
  --silent \
  --show-error \
  --request "GET" \
  --url "${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/pulls?base=${GITHUB_BASE_REF}" \
  --header "Authorization: token ${GITHUB_TOKEN}" \
  --output "pull-requests.json"

for PULL_REQUEST_NUMBER in $(jq ".[] | .number" pull-requests.json); do

  echo ":: Updating PR #${PULL_REQUEST_NUMBER}..."
  curl \
    --silent \
    --show-error \
    --request "PUT" \
    --url "${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}/pulls/${PULL_REQUEST_NUMBER}/update-branch" \
    --header "Authorization: token ${GITHUB_TOKEN_USER}" \
    --header "Accept: application/vnd.github.lydian-preview+json"

done
```
</details>

> :triangular_flag_on_post: Notice that the update script uses a user-provided GitHub token
> in addition to the GitHub-provided one. The latter
> [does not trigger consecutive workflows](https://docs.github.com/en/actions/reference/authentication-in-a-workflow#using-the-github_token-in-a-workflow).
> This means that PRs will be updated but there will be no runs due to new changes.
> [Create a user token](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token) and
> [store it in GitHub secrets](https://docs.github.com/en/actions/reference/encrypted-secrets) to avoid this.

Both scripts should be called from a PR workflow. The integration requires a careful approach.

* A failed merge attempt should not be shown as a run failure.
  Otherwise developers might think that checks failed but it might be as trivial as insufficient review approvals.
* A failed merge attempt should not cause update attempts.

These conditions can be satisfied using a combination of
[a custom shell](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions#using-a-specific-shell)
and [an output parameter](https://docs.github.com/en/actions/reference/workflow-commands-for-github-actions#setting-an-output-parameter).

```yaml
on:
  pull_request:

jobs:
  pull-request-auto-merge:
    runs-on: "ubuntu-latest"

    steps:
    - name: "Checkout the source code"
      uses: actions/checkout@v2

    - name: "Merge"
      id: merge
      shell: "bash --noprofile --norc {0}"
      run: |
        bash .github/workflows/pull-request-merge.sh "${{ secrets.GITHUB_TOKEN }}" "${{ github.event.pull_request.number }}" "${{ github.event.pull_request.title }}"
        echo "::set-output name=merge_status::$?"

    - name: "Update remaining PRs"
      if: steps.merge.outputs.merge_status == 0
      run: bash .github/workflows/pull-request-update.sh "${{ secrets.GITHUB_TOKEN }}" "${{ secrets.USER_GITHUB_TOKEN }}"
```

Don’t forget to duplicate the workflow for PR reviews. This will merge PRs on approvals.

```yaml
on:
  pull_request_review:
    types: "submitted"

jobs:
  pull-request-auto-merge:
    runs-on: "ubuntu-latest"
    ...
```

# Overview

The following combination of files achieves the workflow described in the beginning.

```
.
└── .github
    ├── CODEOWNERS
    └── workflows
        ├── pull-request-cancel-concurrent.sh
        ├── pull-request-merge.sh
        ├── pull-request-review.yml
        ├── pull-request-update.sh
        └── pull-request.yml
```

Of course, some (or all) scripts can be rewritten in JavaScript and published
in the GitHub Actions Marketplace but the goal of this article wasn’t
to provide the shippable _copy-and-use_ solution. In fact, it’s the opposite.

The GitHub API is so flexible and works so well with GitHub Actions that
I encourage everyone to take a look at _their_ workflow and see how it can be
improved.

Do not overuse someone else work. At the moment of writing this article,
[there is a good dozen](https://github.com/marketplace?type=actions&query=cancel+run)
of published actions that cancel a PR. What’s the difference between them?
Is there a maintenance model behind them to follow GitHub API changes?
Is it worth it to bend a workflow to fit them? Sometimes it’s better
to have a couple of scripts doing _exactly_ what needs to be done.
