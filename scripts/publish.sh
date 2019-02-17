#!/bin/bash
set -eu

GENERATOR="${1}"

DIRECTORY="public"
BRANCH="gh-pages"

echo ":: Removing [${DIRECTORY}]."
rm -rf "${DIRECTORY}"

echo ":: Removing [${DIRECTORY}] working tree."
git worktree remove "${DIRECTORY}"

echo ":: Re-creating [${DIRECTORY}] working tree."
git worktree add -B "${BRANCH}" "${DIRECTORY}" origin/"${BRANCH}"

echo ":: Removing [${DIRECTORY}] working tree contents."
rm -rf "${DIRECTORY}"/*

eval "${GENERATOR}"

echo ":: Committing generated contents."
cd "${DIRECTORY}"
git add --all

if [[ -n "${TRAVIS}" ]]; then
  git config user.name "Publisher"
  git config user.email "publisher@localhost"
fi

git commit --message "Publish Hugo-generated contents."

echo ":: Pushing..."
if [[ -z "${TRAVIS_REPO_SLUG}" || -z "${GITHUB_TOKEN}" ]]; then
  git push origin "${BRANCH}"
else
  git push --quiet "https://${GITHUB_TOKEN}:x-oauth-basic@github.com/${TRAVIS_REPO_SLUG}.git" "${BRANCH}"
fi

