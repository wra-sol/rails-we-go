#!/bin/bash
set -e

# Placeholder: In Railway, inject public keys via SECRET_DEPLOY_SSH_KEY
PUBLIC_KEY="${SECRET_DEPLOY_SSH_KEY}"

# Setup deploy user SSH keys
mkdir -p /home/deploy/.ssh
echo "$PUBLIC_KEY" > /home/deploy/.ssh/authorized_keys
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys
chown -R deploy:deploy /home/deploy/.ssh

# SSH configuration
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config 2>/dev/null || true
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config 2>/dev/null || true

# Start SSH server
mkdir -p /var/run/sshd
service ssh start

# Start Node.js app
cd /home/deploy
NODE_ENV=production nohup node index.js > /home/deploy/app.log 2>&1 &

# Simple health output for Railway (optional healthcheck)
while true; do sleep 60; done
