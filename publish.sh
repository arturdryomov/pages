#!/bin/bash

HUGO_DIRECTORY="public"

if [[ $(git status --short) ]]; then
  echo "The working directory is dirty. Please commit any pending changes."
  exit 1
fi

echo ":: Removing [${HUGO_DIRECTORY}] contents."
rm -rf "${HUGO_DIRECTORY}"
mkdir "${HUGO_DIRECTORY}"

echo ":: Removing [${HUGO_DIRECTORY}] working tree."
git worktree prune
rm -rf .git/worktrees/public/

echo ":: Making [${HUGO_DIRECTORY}] working tree."
git worktree add -B gh-pages "${HUGO_DIRECTORY}" origin/gh-pages

echo ":: Removing [${HUGO_DIRECTORY}] working tree contents."
rm -rf "${HUGO_DIRECTORY}"/*

echo ":: Generating..."
hugo

echo ":: Committing..."
cd "${HUGO_DIRECTORY}"
git add --all
git commit -m "Publish Hugo-generated contents."
