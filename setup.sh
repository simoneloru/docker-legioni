#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if [ ! -f .env ]; then
  echo "Creating .env from .env.example..."
  cp .env.example .env
  echo ".env created. Please review and update it if needed."
else
  echo ".env already exists. Skipping."
fi

echo "Building Docker image..."
docker compose build

echo ""
echo "Setup complete. Run the container with:"
echo "  docker compose run --rm dev"
