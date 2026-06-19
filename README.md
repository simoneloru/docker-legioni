# opencode + legioni Docker Dev Environment

[![Build](https://github.com/simoneloru/docker-legioni/actions/workflows/build.yml/badge.svg)](https://github.com/simoneloru/docker-legioni/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-simoneloru%2Fdocker--legioni-blue)](https://hub.docker.com/r/simoneloru/docker-legioni)

Run [opencode](https://opencode.ai) and [legioni](https://www.npmjs.com/package/legioni) in a Docker container with full toolchain support, while keeping your projects on your host filesystem.

> **Windows users:** this project was built with Docker Desktop (WSL2 backend) and Windows paths in mind, but the container itself runs on any Docker host.

## Table of contents

- [Why Docker?](#why-docker)
- [Quick start](#quick-start)
- [Daily workflow](#daily-workflow)
- [Structure](#structure)
- [Git configuration](#git-configuration)
- [GitHub CLI](#github-cli)
- [Makefile commands](#makefile-commands)
- [Two-repo setup](#two-repo-setup)
- [Docker Hub](#docker-hub)
- [Updating pinned versions](#updating-pinned-versions)
- [Stop](#stop)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Why Docker?

opencode and legioni are Linux-native CLI tools. Running them directly on Windows means: npm conflicts, bash agents breaking under PowerShell, and toolchains (Python, Java, Maven) to install individually.

This setup gives you a single-command Linux dev environment with all runtimes pre-installed, while your project files stay on your host — editable in your IDE, live-synced to the container.

- **Linux environment** — bash agents, git, terminal colors work natively
- **One-command setup** — `docker compose run --rm dev` provisions Node.js, Python, Java, Maven, git, GitHub CLI
- **Host filesystem access** — projects live on your host drive, changes appear in real time
- **State isolation** — runtimes and global packages stay in the container, not on your host
- **Reproducible** — the Dockerfile is the source of truth; works on any machine with Docker

## Quick start

### Prerequisites

- Docker with Compose support (e.g. [Docker Desktop](https://www.docker.com/products/docker-desktop/))
- Git

### Setup

```bash
git clone https://github.com/simoneloru/docker-legioni.git
cd docker-legioni
cp .env.example .env
```

On Windows you can also run the provided setup script:

```powershell
.\setup.ps1
```

Edit `.env` and set your workspace path. Example on Windows:

```env
WORKSPACE_PATH=C:\Users\YourName\Documents
```

Example on macOS/Linux:

```env
WORKSPACE_PATH=/home/yourname/projects
```

### Build and run

```bash
docker compose build                  # first time: 2-5 minutes
docker compose run --rm dev           # enter the container
```

Use `--rm` so the container is removed when you exit. Your data lives in volumes and bind mounts, not in the container itself.

You'll get a bash prompt inside the container:

```
dev@opencode-dev:~$
```

Your workspace is mounted at `/workspace`. All projects from your configured path are there.

## Daily workflow

```bash
docker compose run --rm dev           # 1. enter the container
cd /workspace/my-project              # 2. navigate to your project
opencode                               # 3. start coding with AI
```

### Setting up a new project

From inside the container:

```bash
cd /workspace/my-project
git init                                   # if new
legioni init                               # detect stack, write project config
legioni install                            # compile agents from roles + lessons
opencode                                    # start the AI coding agent
```

The first time you run `opencode`, it will prompt you to configure an AI provider and API key. This configuration persists in the `dev-config` volume and survives restarts.

### Promoting lessons

When an agent teaches you something reusable:

```bash
legioni promote "always use slf4j for logging, never System.out"
```

The lesson is saved to `.legioni/lessons/<role>/`. After `legioni install`, it becomes part of the compiled agent.

## Structure

```
docker-legioni/
├── compose.yaml             # service definition and bind mounts
├── Dockerfile               # Node 20 + git + python3 + java + maven + opencode + legioni + gh
├── entrypoint.sh            # auto legioni install on first run
├── .env.example             # template for your local .env
├── .gitignore               # excludes .legioni/ and .env
├── Makefile                 # common commands
├── package.json             # tracks opencode-ai version for Dependabot
├── setup.ps1                # Windows setup helper
├── setup.sh                 # Unix setup helper
└── .legioni/                # your team store (private repo, not committed here)
    ├── roles/               # role definitions (you write these)
    ├── lessons/             # accumulated agent experience (agents write these)
    └── config.json          # team configuration
```

### The `.legioni/` team store

`.legioni/` is a bind mount: it lives on your disk, outside Docker. It holds your team knowledge.

Minimal example:

```
.legioni/
├── config.json
├── roles/
│   └── architect.md
└── lessons/
    └── architect/
        └── logging-conventions.md
```

Example `config.json`:

```json
{
  "team": "my-team",
  "defaults": {
    "language": "en"
  }
}
```

Example `roles/architect.md`:

```markdown
# Architect

You are a senior software architect. You design clean, maintainable systems.
You prefer explicit contracts over implicit behavior.
```

For the full legioni format, see the [legioni package page](https://www.npmjs.com/package/legioni).

### Persistence model

| Path | Type | Survives? |
|---|---|---|
| `.legioni/` | Bind mount (`./.legioni`) | Yes — lives on your disk |
| `~/.config/` | Named Docker volume (`dev-config`) | Yes — survives `docker compose down` |
| `/workspace/` | Bind mount | Yes — lives on your host disk |

**Why `.legioni/` is a bind mount, not a named volume:**

The team store (roles, lessons, config) is data, not config. Lessons grow over time — agents learn from every session. A bind mount lets you:
- Edit roles from your IDE on the host
- Commit lessons to a private git repo
- Never lose experience when rebuilding the image

This is the same model as Redis: the image is the engine, the data lives outside.

## Git configuration

Default: `Dev User <dev@localhost>`. Override via `.env`:

```env
GIT_USER_NAME=Your Name
GIT_USER_EMAIL=you@example.com
```

## GitHub CLI

`gh` is pre-installed. Authenticate once:

```bash
gh auth login
```

The token is saved in `~/.config/gh/`, which is inside the `dev-config` named volume. After authentication, it persists across container restarts.

### Why a single `~/.config/` volume

`~/.config/` is mounted as one named volume. This means opencode, GitHub CLI, and any future CLI configs (GitLab CLI, AWS CLI, Azure CLI, etc.) all persist automatically.

## Makefile commands

A `Makefile` is included for convenience:

```bash
make build    # docker compose build
make run      # docker compose run --rm dev
make clean    # docker compose down -v
make down     # docker compose down
```

## Two-repo setup (recommended)

1. **This repo** (public) — Dockerfile, compose, entrypoint, docs
2. **Private repo** — your team store, cloned into `.legioni/`

```bash
git clone git@github.com:your-username/legioni-team.git .legioni
```

`.legioni/` is already in `.gitignore` here.

## Docker Hub

You can build the image locally or pull/push a pre-built one.

Local build tag (default):

```bash
docker compose build
```

The default image name is `docker-legioni:latest`. To push to Docker Hub, set your username in `.env`:

```env
DOCKER_IMAGE=your-dockerhub-username/docker-legioni:latest
```

Then:

```bash
docker compose build
docker push your-dockerhub-username/docker-legioni:latest
```

## Updating pinned versions

The Dockerfile pins `legioni` and `gh` versions via `ARG`. `opencode` is tracked via `package.json` (handled by Dependabot).

```dockerfile
ARG LEGIONI_VERSION=0.5.1
ARG GH_VERSION=2.95.0
```

To update, change the version numbers and rebuild.

Version updates are automated on this repo:
- **Dependabot** watches `package.json` → opens PRs for `opencode-ai`
- **Weekly workflow** checks npm and GitHub releases → opens PRs for `legioni` and `gh`

## Stop

```bash
docker compose down          # stops container, preserves dev-config volume
docker compose down -v       # stops AND deletes the volume
```

## Troubleshooting

### "WORKSPACE_PATH is not set"

You haven't created `.env` or `WORKSPACE_PATH` is empty. Copy `.env.example` to `.env` and fill it.

### Container starts and exits immediately

Run `docker logs opencode-dev` to see the error. Common causes:
- Missing `.env` or invalid `WORKSPACE_PATH`
- `entrypoint.sh` checked out with CRLF line endings instead of LF (Windows only)

If the line endings are the issue:

```bash
git add --renormalize .
git commit -m "fix line endings"
```

The repo includes a `.gitattributes` file that enforces LF for shell scripts. The `--renormalize` command applies those rules to existing files.

### No files in `/workspace`

Check that `WORKSPACE_PATH` points to an existing directory on your host. Docker may create the directory if it doesn't exist, which can be confusing.

### opencode says "no provider configured"

First launch: configure an AI provider. The settings save in `~/.config/opencode/` inside the `dev-config` volume.

### Permission errors on `.legioni/`

`.legioni/` is a bind mount from the host. Permissions inside the container may look odd, but read/write should work for the `dev` user.

## License

MIT — see [LICENSE](LICENSE).
