#!/bin/bash
set -e

# Define variables for directories and branch name
GIT_DIR="/home/deployer/git/myapp.git"
DEPLOY_DIR="/home/deployer/myapp"
BRANCH="main"
GITHUB_REPO="https://github.com/arley9511/designli-challenge.git"
NGINX_ROOT="/usr/share/nginx/html"

# Create directories if they don't exist
mkdir -p "$(dirname "$GIT_DIR")"
mkdir -p "$DEPLOY_DIR"

# Initialize or reconfigure the bare repository
if [ ! -d "$GIT_DIR" ]; then
  git init --bare "$GIT_DIR"
  git --git-dir="$GIT_DIR" remote add origin "$GITHUB_REPO"
else
  git --git-dir="$GIT_DIR" remote set-url origin "$GITHUB_REPO"
fi

# Create the post-receive hook
HOOK="$GIT_DIR/hooks/post-receive"
cat > "$HOOK" <<'EOF'
#!/bin/bash
set -e
TARGET="/home/deployer/myapp"
GIT_DIR="/home/deployer/git/myapp.git"
BRANCH="main"
NGINX_ROOT="/usr/share/nginx/html"

# Sync with GitHub
git --git-dir="$GIT_DIR" fetch origin "$BRANCH"
git --git-dir="$GIT_DIR" merge origin/"$BRANCH"

while read oldrev newrev ref
do
  if [ "$ref" = "refs/heads/$BRANCH" ]; then
    echo "Ref $ref received. Deploying ${BRANCH} branch to production..."
    
    # Check out the code
    git --work-tree="$TARGET" --git-dir="$GIT_DIR" checkout -f "$BRANCH"
    
    # Sync with GitHub changes
    cd "$TARGET"
    git pull origin "$BRANCH"
    
    # Install dependencies and build
    npm install
    npm run build
    
    # Update Nginx content
    echo "Updating Nginx content..."
    sudo rm -rf "$NGINX_ROOT"/*
    sudo cp -r ./out/* "$NGINX_ROOT"/
    
    # Graceful Nginx restart
    echo "Restarting Nginx..."
    sudo supervisorctl restart nginx
  fi
done
EOF

# Make the hook executable
chmod +x "$HOOK"

# Initial clone of GitHub repository
if [ ! -d "$DEPLOY_DIR/.git" ]; then
  git clone "$GITHUB_REPO" "$DEPLOY_DIR"
fi

# Set permissions for Nginx directory
sudo chown -R deployer:deployer "$NGINX_ROOT"

# Set up auto-sync with GitHub
(crontab -l 2>/dev/null; echo "*/5 * * * * git --git-dir="$GIT_DIR" fetch origin --quiet") | crontab -

echo "Git repository configured at $GIT_DIR with Nginx deployment"
echo "Nginx content directory: $NGINX_ROOT"