#!/bin/bash
set -e

# Fix shared volume permissions so that the git-server can remove/update files.
if [ -d "/app/build" ]; then
  echo "Fixing permissions on /app/build..."
  # Option 1: Set permissive mode (if acceptable)
  chmod -R 777 /app/build
  # Option 2 (preferred if you want controlled access):
  # chown -R gituser:gitgroup /app/build && chmod -R 775 /app/build
fi

# (If you have repository reinitialization logic, include it here.)
REPO_DIR="/home/gituser/repo"

if [ -d "$REPO_DIR" ]; then
  if git -C "$REPO_DIR" rev-parse --is-bare-repository 2>/dev/null | grep -q "true"; then
    echo "Repository at $REPO_DIR is bare."
  else
    echo "Repository at $REPO_DIR is not bare. Removing its contents and reinitializing as bare."
    find "$REPO_DIR" -mindepth 1 -exec rm -rf {} +
    git init --bare "$REPO_DIR"
    cp /home/gituser/hooks/post-receive "$REPO_DIR/hooks/post-receive"
  fi
else
  echo "Repository directory $REPO_DIR does not exist. Creating it as a bare repository."
  mkdir -p "$REPO_DIR"
  git init --bare "$REPO_DIR"
  cp /home/gituser/hooks/post-receive "$REPO_DIR/hooks/post-receive"
fi

# Ensure proper ownership and permissions on the repository
chown -R gituser:gitgroup "$REPO_DIR"
chmod -R 775 "$REPO_DIR"

git config --global --add safe.directory "$REPO_DIR"

exec "$@"
