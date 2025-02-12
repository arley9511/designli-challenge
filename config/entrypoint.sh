#!/bin/bash
set -e

REPO_DIR="/home/gituser/repo"

if [ -d "$REPO_DIR" ]; then
  # Check if the repository is bare
  if git -C "$REPO_DIR" rev-parse --is-bare-repository 2>/dev/null | grep -q "true"; then
    echo "Repository at $REPO_DIR is bare."
  else
    echo "Repository at $REPO_DIR is not bare. Removing its contents and reinitializing as bare."
    # Remove all files and folders inside REPO_DIR without removing the directory itself
    find "$REPO_DIR" -mindepth 1 -exec rm -rf {} +
    git init --bare "$REPO_DIR"
  fi
else
  echo "Repository directory $REPO_DIR does not exist. Creating it as a bare repository."
  mkdir -p "$REPO_DIR"
  git init --bare "$REPO_DIR"
fi

# Ensure the repository directory is owned by gituser and is writable
chown -R gituser:gitgroup "$REPO_DIR"
chmod -R 775 "$REPO_DIR"

git config --global --add safe.directory "$REPO_DIR"

exec "$@"
