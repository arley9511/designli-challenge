# designli-challenge


## Overview

This setup allows a Docker container running on an EC2 instance to automatically sync changes from a remote Git repository and update an Nginx-hosted application. Since there is no direct access to the EC2 instance, the container periodically checks for updates and redeploys when new changes are detected.

## NGROK LINK
https://19a0-186-31-55-96.ngrok-free.app

### Key Components

- Docker: Containerization platform for deploying the application.

- Git: Used to fetch updates from a remote repository.

- Supervisor: Manages long-running processes inside the container.

- Nginx: Serves the built frontend application.

Polling Mechanism: Periodically checks the Git repository for changes and redeploys when updates are available.

### Installation & Setup

1. Build and Run the Docker Container


```bash
docker-composer up
```


This will start the container and automatically begin syncing the repository every 60 seconds.

2. Check Logs

To monitor logs and verify that the sync is working correctly:

docker logs -f designli-challenge-web-1

3. Stopping and Restarting the Container

To stop the container:

docker stop designli-challenge-web-1

To restart the container:

docker start designli-challenge-web-1

