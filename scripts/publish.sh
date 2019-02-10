#!/bin/bash

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

bash "scripts/assemble.sh"

echo ":: Committing generated contents."
cd "${DIRECTORY}"
git add --all
git commit --message "Publish Hugo-generated contents."

echo ":: Pushing..."
if [[ -z "${TRAVIS_REPO_SLUG}" || -z "${GITHUB_TOKEN}" ]]; then
  git push origin "${BRANCH}"
else
  git config --global user.name "Publisher"
  git config --global user.email "publisher@localhost"

  git push --quiet "https://${GITHUB_TOKEN}:x-oauth-basic@github.com/${TRAVIS_REPO_SLUG}.git" "${BRANCH}"
fi

