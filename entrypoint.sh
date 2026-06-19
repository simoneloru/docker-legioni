#!/bin/bash
set -e

if [ -n "$GIT_USER_NAME" ]; then
    git config --global user.name "$GIT_USER_NAME"
fi

if [ -n "$GIT_USER_EMAIL" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
fi

mkdir -p ~/.legioni/roles ~/.legioni/lessons ~/.config/opencode/agents

if [ -z "$(ls -A ~/.config/opencode/agents 2>/dev/null)" ] \
    && [ -n "$(ls -A ~/.legioni/roles 2>/dev/null)" ]; then
    echo "First run: compiling agents..."
    legioni install
fi

if [ $# -eq 0 ]; then
    exec bash
else
    exec "$@"
fi