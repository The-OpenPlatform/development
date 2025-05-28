#!/bin/bash

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "git is not installed. Aborting."
    exit 1
fi

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo "docker is not installed. Aborting."
    exit 1
fi

echo "==================================================================="
echo "  WARNING: This setup is for DEVELOPMENT purposes only."
echo "  Do NOT use this environment for production workloads."
echo "==================================================================="
read -p "Do you understand and wish to continue? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Aborting setup."
    exit 1
fi

# Copy example.env to .env if .env does not exist
if [ -f "example.env" ] && [ ! -f ".env" ]; then
    cp example.env .env
    echo "Copied example.env to .env"
fi

# List of repositories to clone
REPOS=(
    "git@github.com:The-OpenPlatform/frontend.git"
    "git@github.com:The-OpenPlatform/backend.git"
    "git@github.com:The-OpenPlatform/database.git"
)

# Clone each repository into the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for REPO in "${REPOS[@]}"; do
    FOLDER=$(basename "$REPO" .git)
    TARGET_DIR="$SCRIPT_DIR/$FOLDER"
    if [ -d "$TARGET_DIR" ]; then
        echo "Directory $FOLDER already exists in script directory. Pulling latest changes."
        git -C "$TARGET_DIR" pull
    else
        echo "Cloning $REPO into $SCRIPT_DIR"
        git clone "$REPO" "$TARGET_DIR"
    fi
done

# Ask if docker compose should be executed
read -p "Do you want to execute 'docker compose up -d'? (y/n): " RUN_COMPOSE

if [[ "$RUN_COMPOSE" =~ ^[Yy]$ ]]; then
    if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
        docker compose up -d
        echo "Fetching exposed ports for running containers..."
        docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -E 'frontend|backend|database' | while read -r NAME PORTS; do
            APP=$(echo "$NAME" | awk '{print $1}')
            PORT=$(echo "$PORTS" | grep -oE '[0-9\.]+:[0-9]+' | head -n1)
            if [ -n "$PORT" ]; then
                HOST_IP=$(echo "$PORT" | cut -d: -f1)
                HOST_PORT=$(echo "$PORT" | cut -d: -f2)
                echo "$APP is exposed at http://$HOST_IP:$HOST_PORT"
            else
                echo "Could not determine port for $APP"
            fi
        done
    else
        echo "No docker-compose.yml file found in current directory."
    fi
else
    echo "Skipping docker compose."
fi