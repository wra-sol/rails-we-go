#!/bin/bash
set -e

MARKER="$OPENCODE_INSTALLED_FLAG"
DATA_DIR="/data"
DEploy_HOME="/home/deploy"

# Ensure data dir exists if volume mounted
mkdir -p "$DATA_DIR"
mkdir -p "$DATA_DIR/.config"

PUBLIC_KEY="${SECRET_DEPLOY_SSH_KEY:-}"
AUTH_KEYS_DIR="$DEploy_HOME/.ssh"
AUTHORIZED_KEYS="$AUTH_KEYS_DIR/authorized_keys"

# 1) SSH keys setup (idempotent)
mkdir -p "$AUTH_KEYS_DIR"
if [ -n "$PUBLIC_KEY" ]; then
  echo "$PUBLIC_KEY" > "$AUTHORIZED_KEYS"
  chmod 700 "$AUTH_KEYS_DIR"
  chmod 600 "$AUTHORIZED_KEYS"
fi

# 2) SSH config hardening (idempotent)
if ! grep -q "PasswordAuthentication no" /etc/ssh/sshd_config 2>/dev/null; then
  echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
fi
if ! grep -q "PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null; then
  echo "PermitRootLogin no" >> /etc/ssh/sshd_config
fi

# 3) Idempotent Opencode installation
if [ ! -f "$MARKER" ]; then
  echo "Installing opencode..."
  curl -fsSL https://opencode.ai/install | bash
  touch "$MARKER"
else
  echo "Opencode already installed; skipping installation."
fi

# 4) Start services
mkdir -p /var/run/sshd
/usr/sbin/sshd -D &
SSH_PID=$!

# Start Node.js app
cd "$DEploy_HOME"
PORT="${PORT:-3000}"
export PORT

# Start the app in the background; opencode may manage tasks, otherwise start the app directly
if [ -f "/home/deploy/index.js" ]; then
  node index.js > /home/deploy/app.log 2>&1 &
fi

# Wait forever
wait $SSH_PID
