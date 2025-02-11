#!/bin/bash
set -e

#############################################
# CONFIGURATION VARIABLES
#############################################
TARGET="/app/frontend"                          # Working tree / deployment directory
BARE_REPO="/app/frontend/git/frontend.git"           # Path to the bare repository for hooks
NGINX_ROOT="/usr/share/nginx/html"               # Nginx document root
BRANCH="main"                                   # Deployment branch
GITHUB_REPO="https://github.com/arley9511/designli-challenge.git"

#############################################
# FUNCTION: setup_repo
# Sets up the bare repository and installs the post-receive hook.
#############################################
setup_repo() {
    echo "Setting up bare repository..."
    if [ ! -d "$BARE_REPO/HEAD" ]; then
        # Create parent directory for bare repo if needed
        mkdir -p "$(dirname "$BARE_REPO")"
        echo "Initializing bare repository at $BARE_REPO..."
        mkdir -p "$BARE_REPO"
        git init --bare "$BARE_REPO"

        # Set up the post-receive hook to update the working tree at TARGET.
        HOOK_FILE="$BARE_REPO/hooks/post-receive"
        echo "Creating post-receive hook at $HOOK_FILE..."
        cat > "$HOOK_FILE" << 'EOF'
#!/bin/sh
# Post-receive hook: update the working tree
git --work-tree=/app/frontend --git-dir=/app/frontend/git/frontend.git checkout -f
supervisorctl start git-setup
EOF
        chmod +x "$HOOK_FILE"
        echo "Post-receive hook created."
    else
        echo "Bare repository already exists at $BARE_REPO."
    fi
}

#############################################
# FUNCTION: deploy
# Performs the deployment: syncs (clone or pull), builds, and updates Nginx.
#############################################
deploy() {
    echo "Deployment started at $(date)"

    # --- Sync process: clone or pull repository into TARGET ---
    if [ -d "$TARGET/.git" ]; then
        echo "Pulling latest changes in $TARGET..."
        cd "$TARGET"
        git pull origin "$BRANCH"
    else
        # If TARGET exists but is not a git repository, clean it first.
        if [ -d "$TARGET" ] && [ "$(ls -A "$TARGET")" ]; then
            echo "Target directory $TARGET exists and is not empty; cleaning it..."
            rm -rf "$TARGET"/*
        fi
        echo "Cloning repository from $GITHUB_REPO into $TARGET..."
        git clone -b "$BRANCH" "$GITHUB_REPO" "$TARGET"
    fi

    # --- Build process ---
    # Adjust the directory change if your project structure requires it.
    if [ -d "$TARGET/frontend" ]; then
        cd "$TARGET/frontend"
    else
        cd "$TARGET"
    fi

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
