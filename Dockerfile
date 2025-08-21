# filepath: /Users/ladmin/WebProjects/rails-we-go/Dockerfile
# Minimal Docker VPS with SSH and Node.js app for Railway
FROM ubuntu:22.04

# Non-interactive apt
ENV DEBIAN_FRONTEND=noninteractive

# Install SSH, curl, git, and minimal tools
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        openssh-server \
        curl \
        ca-certificates \
        git \
        nano \
        locales \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen en_US.UTF-8

# Create deploy user
RUN useradd -m -s /bin/bash deploy \
    && echo 'deploy ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# SSH config: listen on port 22, passwordless, no root login (we'll harden at bootstrap)
RUN mkdir -p /var/run/sshd
EXPOSE 22 3000

# Bootstrap at startup
COPY bootstrap.sh /bootstrap.sh
RUN chmod +x /bootstrap.sh

# Copy minimal app scaffold
COPY index.js /home/deploy/index.js
COPY package.json /home/deploy/package.json

WORKDIR /home/deploy

# Install Node.js (setup 18.x) in bootstrap or here
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && npm install --only=prod --prefix /home/deploy

# SSH server should run in front; start script serves as entrypoint
CMD ["/bootstrap.sh"]
