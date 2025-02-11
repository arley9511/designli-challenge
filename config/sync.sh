#!/bin/bash
set -e

#############################################
# CONFIGURATION VARIABLES
#############################################
TARGET="/app/repo"                          # Working tree / deployment directory
NGINX_ROOT="/usr/share/nginx/html"               # Nginx document root
BRANCH="main"                                   # Deployment branch
GITHUB_REPO="https://github.com/arley9511/designli-challenge.git"

#############################################
# FUNCTION: setup_repo
# Sets up the bare repository and installs the post-receive hook.
#############################################
setup_repo() {
    echo "Cloning repository from $GITHUB_REPO into $TARGET..."
    git clone -b "$BRANCH" "$GITHUB_REPO" "$TARGET"

    ls -la $TARGET

    # Set up the post-receive hook to update the working tree at TARGET.
    HOOK_FILE="$TARGET/.git/hooks/post-receive"
    touch "$HOOK_FILE"
    echo "Creating post-receive hook at $HOOK_FILE..."
    cat > "$HOOK_FILE" <<EOF
    #!/bin/sh
    exec > /dev/stdout 2>&1
    # Post-receive hook: update the working tree
    git --work-tree=/app/repo checkout -f
    supervisorctl start git-setup
EOF

    chmod +x "$HOOK_FILE"
    echo "Post-receive hook created."
}

#############################################
# FUNCTION: deploy
# Performs the deployment: sync, build, and update Nginx.
#############################################
deploy() {
    echo "Deployment started at $(date)"
    
    echo "Pulling latest changes in $TARGET..."
    cd "$TARGET"
    git pull origin "$BRANCH"

    # --- Build process ---
    cd "$TARGET/frontend"

    echo "Installing dependencies..."
    npm install
    echo "Building application..."
    npm run build

    # --- Deployment to Nginx ---
    echo "Updating web root at $NGINX_ROOT..."
    rm -rf "${NGINX_ROOT:?}"/*
    cp -r ./out/* "$NGINX_ROOT"/

    echo "Reloading Nginx..."
    supervisorctl restart nginx

    echo "Deployment completed at $(date)"
}

#############################################
# MAIN SCRIPT EXECUTION
#############################################

# 1. Set up the bare repository and its post-receive hook.
setup_repo

# 2. Perform the initial deployment from the remote GitHub repository.
deploy
