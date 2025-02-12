# Next.js Deployment via Git Push
This project demonstrates an automated deployment workflow using Docker containers. A Git server accepts pushes via SSH, triggering a post-receive hook that builds a Next.js application. The built artifacts are stored on a shared volume that the Nginx container uses to serve the application. An ngrok container exposes the site externally via a secure tunnel.

## Table of Contents
- NGROK link
- Overview
- Architecture
- Components
- Setup and Configuration
- How It Works
- How to Test the Deployment

### NGROK link
https://2792-186-31-55-96.ngrok-free.app

### Overview
When you push code to the Git server using a command such as:

```bash
git push docker main
```

the Git server’s post-receive hook automatically checks out the latest commit, builds the Next.js application, and synchronizes the build artifacts to a shared volume. The Nginx container then serves these files, and the ngrok container creates a public URL for external access.

### Architecture
The solution uses Docker Compose to orchestrate three main services:

- git-server

Role: Hosts a bare Git repository accessible via SSH.
Deployment Trigger: A post-receive hook builds the Next.js app upon a push.
Shared Volume: Writes build artifacts to a shared volume.

- nginx

Role: Serves the built Next.js application.
Configuration: Uses a custom Nginx configuration (mounted via ./config/nginx.conf).
Shared Volume: Mounts the build volume in read-only mode.

- ngrok

Role: Exposes the Nginx service to the Internet via a secure tunnel.
Configuration: Requires an authentication token provided through an environment variable.
Two named volumes are defined:

- git-repo: Persists the Git repository.
- nextjs-build: Holds the Next.js build artifacts and is shared between git-server and nginx.

### Components
- Git Server
- Docker Image: Built using a custom Dockerfile.
- Repository: Configured as a bare repository located at /home/gituser/repo.
- Post-Receive Hook:
Reads push information from STDIN.
Checks out the pushed code into a temporary directory.
Installs dependencies and builds the Next.js app.
Synchronizes build artifacts to /app/build (a volume shared with nginx).
SSH Access: Uses SSH to accept Git pushes. The image generates SSH host keys during build so that the SSH daemon can run.
- Nginx
- Docker Image: Uses nginx:alpine.
- Configuration: A custom configuration is provided via ./config/nginx.conf (mounted into /etc/nginx/conf.d/default.conf).
Volume Mount: Mounts the shared build volume (nextjs-build) at /usr/share/nginx/html in read-only mode.
- Ngrok
Docker Image: Uses ngrok/ngrok:alpine.
Purpose: Exposes the Nginx service externally on a secure public URL.
Authentication: Requires an authentication token provided through the NGROK_AUTHTOKEN environment variable.

### Setup and Configuration
1. Clone or Create Your Project Repository
Set up your Next.js project with your desired structure. Ensure that your repository contains either the Next.js project in the root or a subdirectory (e.g., frontend) if you’ve configured the post-receive hook accordingly.

2. Docker Compose Configuration
Below is an example docker-compose.yml that defines the services and shared volumes. In this example, the git-server runs with privileges and the nginx service is set to run as root (removing any user override) so that both containers operate with consistent permissions on the shared volume.
3. Configure Git Remote
To allow you to push code to the Git server, add a remote pointing to the Git server’s SSH URL:


```bash
git remote add docker ssh://gituser@localhost:2222/home/gituser/repo
```
### How It Works
- Push Code:
Developers push changes to the Git server:

```bash
git push docker main
```

This command pushes the main branch to the Git server, which is reachable at the SSH URL defined above.

- Post-Receive Hook:
Upon receiving the push, the Git server’s post-receive hook:

- Reads the push details.
Checks out the latest commit into a temporary directory.
Executes npm install and npm run build to build the Next.js app.
Synchronizes the build artifacts to /app/build using file synchronization (rsync or similar).
Deployment:
- The nginx container, which mounts the shared volume as /usr/share/nginx/html, immediately serves the updated application.

- Public Access:
The ngrok container creates a public URL to access the deployed application externally.

### How to Test the Deployment
Start Services:
Run the following commands to build and start all services:

```bash
docker-compose down -v
docker-compose up --build -d
```

Add Git Remote (if not done already):
In your local repository, add the Git remote:

```bash
git remote add docker ssh://gituser@localhost:2222/home/gituser/repo

```
Push Changes:
Push your changes to trigger the deployment:

```bash
git push docker main
```
You should see output from the post-receive hook indicating that it is checking out the code, building the application, and synchronizing build artifacts.

### Verify Deployment:

- Check the logs of the git-server container for deployment messages:

```bash
docker-compose logs git-server

```

- Check the public URL provided by ngrok:

```bash
docker-compose logs ngrok
```
You can also visit http://localhost in your browser (if nginx is mapped to port 80) to see the deployed application.