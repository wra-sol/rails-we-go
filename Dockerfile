# filepath: /Users/ladmin/WebProjects/rails-we-go/Dockerfile
# Minimal Docker VPS with SSH and Node.js app for Railway (Volume-aware)
FROM ubuntu:22.04

# Non-interactive apt
ENV DEBIAN_FRONTEND=noninteractive

# Do NOT declare a Dockerfile VOLUME here. Railway will attach a volume at runtime
# and provide mount path via environment variables: RAILWAY_VOLUME_MOUNT_PATH

# Install SSH, curl, git, unzip (unzip kept for installer compatibility), and minimal tools
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        openssh-server \
        curl \
        ca-certificates \
        git \
        unzip \
        nano \
        locales \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen en_US.UTF-8

# Create deploy user
RUN useradd -m -s /bin/bash deploy \
    && echo 'deploy ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Switch to non-root user for runtime (best practice)
# We will switch to 'deploy' in bootstrap for runtime tasks; keep root for install steps if needed.

EXPOSE 22 3000

# Bootstrap at startup
COPY bootstrap.sh /bootstrap.sh
RUN chmod +x /bootstrap.sh

# Copy minimal app scaffold
COPY index.js /home/deploy/index.js
COPY package.json /home/deploy/package.json

WORKDIR /home/deploy

# Node setup (still installs at build time)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && npm install --prefix /home/deploy

# Use Railway-provided mount path at runtime; default to /data if not set
ENV OPENCODE_INSTALLED_FLAG /data/.opencode_installed

# Start bootstrap
CMD ["/bootstrap.sh"]
