# VPS on Railway (Docker-based)
A minimal Ubuntu-based VPS container with an SSH endpoint and a tiny Node.js app, designed to run on Railway. SSH access is key-based and provided via a bootstrap mechanism that injects your public key at startup.

## Overview
- Base image: Ubuntu 22.04
- Services:
  - OpenSSH server (SSH into the container)
  - Node.js app (listening on port 3000)
- Ports (Docker): 
  - SSH: 22 inside container, exposed to host as 2222 (configurable)
  - App: 3000
- Bootstrap: Uses a startup script to:
  - Create a non-root deploy user
  - Populate authorized_keys from a Railway secret (SECRET_DEPLOY_SSH_KEY) or from a mounted authorized_keys file
  - Harden SSH (no password login, no root login)
  - Start SSH and the Node.js app

## Persistence with Railway Volumes
Railway volumes are mounted at runtime and accessed inside the container at a path you configure via environment variables.
- Use:
  - RAILWAY_VOLUME_MOUNT_PATH to specify the mount point inside the container (default: /data)
  - RAILWAY_VOLUME_NAME (optional, for volume identification in Railway)
- The app and bootstrap now use the path you configure as the persistence directory.
- To enable SSH and opencode boot, supply SECRET_DEPLOY_SSH_KEY as a secret in Railway (public key content).

### Environment configuration (Railway)
- RAILWAY_VOLUME_MOUNT_PATH=/data
- RAILWAY_VOLUME_NAME=your-volume-name
- SECRET_DEPLOY_SSH_KEY="<your-public-key>"

## Project structure
- Dockerfile: Docker image definition
- bootstrap.sh: Startup bootstrap to configure SSH and run the app
- index.js: Minimal Node.js app with a /health endpoint
- package.json: npm configuration and dependencies
- README.md: This file

## Prerequisites
- Docker installed locally for testing
- Node.js 18.x (as used in this project)
- SSH key pair (private key on your host, public key to deploy)
- Railway account (for deployment)

## Files

- Dockerfile
  - Base: ubuntu:22.04
  - Installs OpenSSH, curl, git, unzip (unzip kept for installer compatibility), and minimal tools
  - Creates a non-root user `deploy`
  - Exposes 22 and 3000
  - Note: Docker VOLUME removed; Railway handles persistence via volumes at runtime

- bootstrap.sh
  - Reads SECRET_DEPLOY_SSH_KEY (your public key content)
  - Creates /home/deploy/.ssh/authorized_keys with the public key (path resolved at runtime to the mount path)
  - Sets permissions for SSH keys
  - Harden SSH: PasswordAuthentication no, PermitRootLogin no
  - Idempotent Opencode installation guarded by marker in /data (or mounted path)
  - Starts the SSH daemon and the Node.js app (index.js)
  - Uses RAID/RAILWAY_* env vars for mount path and settings

- index.js
  - Simple HTTP server on port 3000
  - /health endpoint returns ok

- package.json
  - Basic Node.js app metadata
  - "start": "node index.js"

## Local development and testing

1) Build the Docker image
- docker build -t vps-railway-demo:latest .

2) Run the container locally (map host ports)
- docker run -d \
  -p 2222:22 \
  -p 3000:3000 \
  --name vps-railway-demo \
  vps-railway-demo:latest

3) Provide your SSH public key to the container
- Option A — via environment variable (SECRET_DEPLOY_SSH_KEY)
  - docker run -d \
    -p 2222:22 \
    -p 3000:3000 \
    -e SECRET_DEPLOY_SSH_KEY="$(cat ~/.ssh/id_rsa.pub)" \
    --name vps-railway-demo \
    vps-railway-demo:latest
- Option B — mount an authorized_keys file
  - mkdir -p /tmp/vps-railway
  - echo "<your-public-key-content>" > /tmp/vps-railway/authorized_keys
  - docker run -d \
    -p 2222:22 \
    -p 3000:3000 \
    -v /tmp/vps-railway/authorized_keys:/home/deploy/.ssh/authorized_keys:ro \
    --name vps-railway-demo \
    vps-railway-demo:latest

4) SSH into the container
- ssh -i ~/.ssh/id_rsa deploy@localhost -p 2222

5) Check app health
- curl http://localhost:3000/health
- Expected: ok

## Deploying to Railway (Docker-based)

1) Build and push the image to Railway’s registry
- docker build -t vps-railway-demo:latest .
- docker tag vps-railway-demo:latest registry.railway.app/your-namespace/vps-railway-demo:latest
- docker push registry.railway.app/your-namespace/vps-railway-demo:latest

2) Create a Railway service from the image
- railway login
- railway init
- railway up -d
  - If you’re prompted, choose to deploy using Docker image
- Note: If you prefer, connect a Git repo and let Railway build automatically; this guide uses a pre-built image approach.

3) Inject SSH key (secret) for bootstrap
- In Railway project settings, add a secret:
  - Name: SECRET_DEPLOY_SSH_KEY
  - Value: contents of your id_rsa.pub
- If you used the mounted-keys approach, this secret is not needed.

4) Expose ports
- Ensure Railway service exposes:
  - SSH: map container 22 to a public port (Railway will provide a host:port)
  - App: 3000 (for health checks or app routes)
- If Railway does not expose SSH directly, you may only access the app via HTTP. Use the provided Railway URL for health checks, e.g., curl http://<railway-url>/health

5) Connect to the deployed container (if SSH is exposed)
- ssh -i ~/.ssh/id_rsa deploy@<railway-host> -p <ssh-port>

6) Validate
- App health: curl http://<railway-host-or-url>:<port>/health
- SSH (if available): ssh -i ~/.ssh/id_rsa deploy@<railway-host> -p <ssh-port>

## Security notes
- Use key-based SSH only; disable password authentication
- Do not hard-code private keys in the image
- Rotate SSH keys by updating the secret and re-deploy
- Keep dependencies up to date

## Troubleshooting
- “Permission denied (publickey)”:
  - Ensure the public key in SECRET_DEPLOY_SSH_KEY matches your private key
  - Ensure /home/deploy/.ssh/authorized_keys contains the key
  - Ensure permissions: /home/deploy/.ssh (700), /home/deploy/.ssh/authorized_keys (600)
- “Connection refused”:
  - Verify container is running and port mappings are correct
  - Check bootstrap.sh starts sshd and the app

## Next steps (optional)
- Add a GitHub Actions workflow to automate builds and deployments to Railway
- Replace the simple Node app with your real app (same port mapping)
- Add basic health checks, logging, and metrics

---

If you want, I can tailor this README with your exact Railway project name, namespace, and any custom port or runtime adjustments. Just share the precise values you’re using on Railway (service name, registry namespace, and whether SSH will be exposed publicly).
