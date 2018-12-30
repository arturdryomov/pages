#!/bin/bash

HUGO_DIRECTORY="public"
PUBLISH_BRANCH="gh-pages"

if [[ $(git status --short) ]]; then
  echo "Please commit pending changes."
  exit 1
fi

echo ":: Removing [${HUGO_DIRECTORY}]."
rm -rf "${HUGO_DIRECTORY}"

echo ":: Removing [${HUGO_DIRECTORY}] working tree."
git worktree remove "${HUGO_DIRECTORY}"

echo ":: Making [${HUGO_DIRECTORY}] working tree."
git worktree add -B "${PUBLISH_BRANCH}" "${HUGO_DIRECTORY}" origin/"${PUBLISH_BRANCH}"

echo ":: Removing [${HUGO_DIRECTORY}] working tree contents."
rm -rf "${HUGO_DIRECTORY}"/*

echo ":: Generating..."
hugo

echo ":: Committing generated contents."
cd "${HUGO_DIRECTORY}"
git add --all
git commit --message "Publish Hugo-generated contents."

echo ":: Pushing..."
git push origin "${PUBLISH_BRANCH}"
