#!/bin/bash
set -eou pipefail

GENERATOR="${1}"

GITHUB_TOKEN="${2}"
GITHUB_REPO="${3}"
GITHUB_BRANCH="gh-pages"

DIRECTORY="public"

echo ":: Removing [${DIRECTORY}] directory."
rm -rf "${DIRECTORY}"

echo ":: Removing [${DIRECTORY}] Git working tree."
set +e
# This command produced an error if there is no worktree, even with the force option.
git worktree remove "${DIRECTORY}" --force
set -e

echo ":: Re-creating [${DIRECTORY}] Git working tree."
git worktree add -B "${GITHUB_BRANCH}" "${DIRECTORY}" origin/"${GITHUB_BRANCH}"

echo ":: Removing [${DIRECTORY}] Git working tree contents."
rm -rf "${DIRECTORY:?}"/*

eval "${GENERATOR}"

echo ":: Committing generated contents."
cd "${DIRECTORY}"
git add --all

if [[ -n "${CI}" ]]; then
  git config user.name "Publisher"
  git config user.email "publisher@localhost"
fi

git commit --message "Publish Hugo-generated contents." --allow-empty

echo ":: Pushing..."
if [[ -z "${GITHUB_TOKEN}" || -z "${GITHUB_REPO}" ]]; then
  git push origin "${GITHUB_BRANCH}"
else
  git push --quiet "https://${GITHUB_TOKEN}:x-oauth-basic@github.com/${GITHUB_REPO}.git" "${GITHUB_BRANCH}"
fi

