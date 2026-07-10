#!/usr/bin/env bash
set -euo pipefail

REPO="simoneloru/docker-legioni"
BRANCH="main"
GITHUB_RAW="https://raw.githubusercontent.com/$REPO/$BRANCH"
DEFAULT_WORKSPACE="$HOME/workspace"

# --- detect local mode ---
if [ -f "./compose.yaml" ]; then
    LOCAL=true
    DIR="."
else
    LOCAL=false
    DIR="./docker-legioni"
fi

echo "================================================"
echo "  $REPO — setup"
echo "================================================"
echo ""

# --- create directory ---
if [ "$LOCAL" = false ]; then
    if [ -d "$DIR" ]; then
        echo "Directory $DIR already exists. Using it."
    else
        mkdir -p "$DIR"
        echo "Created $DIR"
    fi
fi

cd "$DIR"

# --- get workspace path ---
DEFAULT_WORKSPACE="${WORKSPACE_PATH:-$DEFAULT_WORKSPACE}"
read -r -p "Where are your projects? [$DEFAULT_WORKSPACE]: " input
WORKSPACE_PATH="${input:-$DEFAULT_WORKSPACE}"
echo ""

# --- get compose.yaml ---
if [ "$LOCAL" = true ]; then
    echo "Local mode: using existing compose.yaml"
else
    echo "Downloading compose.yaml..."
    curl -fsSL -o compose.yaml "$GITHUB_RAW/compose.yaml"
    echo "Downloading .devcontainer/devcontainer.json..."
    mkdir -p .devcontainer
    curl -fsSL -o .devcontainer/devcontainer.json "$GITHUB_RAW/.devcontainer/devcontainer.json"
fi

# --- create .env ---
cat > .env <<EOF
# Created by setup.sh — you can edit this file later
WORKSPACE_PATH=$WORKSPACE_PATH
DOCKER_IMAGE=simoneloru/docker-legioni:latest
GIT_USER_NAME=${GIT_USER_NAME:-Dev User}
GIT_USER_EMAIL=${GIT_USER_EMAIL:-dev@localhost}
EOF

echo ".env created with WORKSPACE_PATH=$WORKSPACE_PATH"
echo ""

# --- pull image ---
echo "Pulling Docker image..."
docker compose pull
echo ""

# --- done ---
echo "================================================"
echo "  Setup complete!"
echo "================================================"
echo ""
echo "  Daily use:"
echo "    cd $(pwd) && docker compose run --rm dev"
echo ""
