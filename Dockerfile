FROM ubuntu:latest

# Install dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git \
    openssh-server \
    nodejs \
    npm \
    rsync \
    && rm -rf /var/lib/apt/lists/*

# Create user with fixed UID/GID
RUN groupadd -g 1001 gitgroup && \
    useradd -m -u 1001 -g gitgroup -s /bin/bash gituser && \
    echo "gituser:gituser" | chpasswd

# Configure SSH
RUN mkdir -p /var/run/sshd && \
    chown root:root /var/run/sshd && \
    chmod 0755 /var/run/sshd && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#StrictModes yes/StrictModes no/' /etc/ssh/sshd_config

# Generate SSH host keys so sshd can start
RUN ssh-keygen -A

# Set up build directory with correct permissions
RUN mkdir -p /app/build && \
    chown -R gituser:gitgroup /app/build

# Configure Git repository
USER gituser
RUN mkdir -p /home/gituser/repo && \
    cd /home/gituser/repo && \
    git init --bare

# Copy and configure post-receive hook
COPY --chown=gituser:gitgroup config/post-receive /home/gituser/hooks/post-receive
RUN chmod +x /home/gituser/hooks/post-receive

# Entrypoint to fix permissions
USER root
COPY ./config/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["/usr/sbin/sshd", "-D"]
