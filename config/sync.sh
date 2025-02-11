#!/bin/bash
set -e

#############################################
# CONFIGURATION VARIABLES (customize as needed)
#############################################
TARGET="/app/frontend"                   # Directory where the repository will be cloned
NGINX_ROOT="/usr/share/nginx/html"       # Nginx document root
BRANCH="main"                            # Deployment branch
GITHUB_REPO="https://github.com/arley9511/designli-challenge.git"

#############################################
# FUNCTION: deploy
# Contains the deployment steps used both at startup and on hook trigger.
#############################################
deploy() {
    echo "Deployment started at $(date)"

    # If TARGET is not a git repository, clone it. Otherwise, pull the latest changes.
    if [ ! -d "$TARGET/.git" ]; then
        echo "Cloning repository from $GITHUB_REPO..."
        git clone -b "$BRANCH" "$GITHUB_REPO" "$TARGET"
    else
        echo "Pulling latest changes in $TARGET..."
        cd "$TARGET"
        git pull origin "$BRANCH"
    fi

    # Navigate to the project directory (adjust if your repository structure differs)
    if [ -d "$TARGET/frontend" ]; then
        cd "$TARGET/frontend"
    else
        cd "$TARGET"
    fi

    # Install dependencies and build the application
    echo "Installing dependencies..."
    npm install
    echo "Building application..."
    npm run build

    # Update Nginx content: Remove old files and copy new build output
    echo "Updating web root at $NGINX_ROOT..."
    rm -rf "${NGINX_ROOT:?}"/*
    cp -r ./out/* "$NGINX_ROOT"/

    # Reload Nginx gracefully (ensure supervisorctl is configured in your container)
    echo "Reloading Nginx..."
    supervisorctl restart nginx

    echo "Deployment completed at $(date)"
}

#############################################
# MAIN SCRIPT EXECUTION
#############################################
deploy

# Git hook, Git pipes in "oldrev newrev ref" lines.
while read -r oldrev newrev ref; do
    if [ "$ref" = "refs/heads/$BRANCH" ]; then
        echo "Detected push to $BRANCH; triggering deployment."
        deploy
    fi
done
