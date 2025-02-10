# Use the official Ubuntu base image
FROM ubuntu:latest

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies, Node.js LTS, Nginx, and Supervisor
RUN apt-get update && \
    apt-get install -y \
    curl \
    gnupg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Add NodeSource repository for Node.js LTS
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -

# Install Node.js LTS, Nginx, and Supervisor
RUN apt-get install -y nodejs nginx supervisor

# Remove default Nginx configuration
RUN rm -rf /etc/nginx/sites-enabled/default

# Copy custom Nginx configuration (reverse proxy for Node.js)
COPY nginx.conf /etc/nginx/sites-available/app
RUN ln -s /etc/nginx/sites-available/app /etc/nginx/sites-enabled/

# Copy Supervisor configuration to manage both Nginx and Node.js
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Set the working directory and copy app files
WORKDIR /app
COPY . /app

# Expose ports for Nginx 80
EXPOSE 80

# Start Supervisor to manage Nginx and Node.js processes
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
