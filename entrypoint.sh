#!/bin/bash
set -e

# Fix named volume ownership (Docker creates volumes as root)
chown -R dev:dev /home/dev/.config 2>/dev/null || true

# Create required directories
mkdir -p /home/dev/.legioni/roles /home/dev/.legioni/lessons /home/dev/.config/opencode/agents

# Symlink .gitconfig into the dev-config volume so changes persist
if [ ! -L /home/dev/.gitconfig ]; then
    if [ -f /home/dev/.config/gitconfig ]; then
        # Volume has a saved gitconfig from a previous session
        mv /home/dev/.gitconfig /home/dev/.gitconfig.bak 2>/dev/null || true
    else
        # First run: move the file baked in the image into the volume
        mv /home/dev/.gitconfig /home/dev/.config/gitconfig 2>/dev/null || touch /home/dev/.config/gitconfig
    fi
    ln -sf /home/dev/.config/gitconfig /home/dev/.gitconfig
    chown -h dev:dev /home/dev/.gitconfig
fi

# Set git config for dev user
if [ -n "$GIT_USER_NAME" ]; then
    su dev -c "git config --global user.name '$GIT_USER_NAME'"
fi
if [ -n "$GIT_USER_EMAIL" ]; then
    su dev -c "git config --global user.email '$GIT_USER_EMAIL'"
fi

# Auto legioni install on first run
if [ -z "$(ls -A /home/dev/.config/opencode/agents 2>/dev/null)" ] \
    && [ -n "$(ls -A /home/dev/.legioni/roles 2>/dev/null)" ]; then
    echo "First run: compiling agents..."
    su dev -c "legioni install"
fi

# Switch to dev user
if [ $# -eq 0 ]; then
    exec su dev
else
    exec su dev -c "exec $*"
fi
