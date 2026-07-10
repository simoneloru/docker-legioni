# opencode + legioni Docker Dev Environment

[![Build](https://github.com/simoneloru/docker-legioni/actions/workflows/build.yml/badge.svg)](https://github.com/simoneloru/docker-legioni/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-simoneloru%2Fdocker--legioni-blue)](https://hub.docker.com/r/simoneloru/docker-legioni)

Run [opencode](https://opencode.ai) and [legioni](https://github.com/simoneloru/legioni) in a Docker container with the stack you need, while keeping your projects on your host filesystem.

## Quick start

**Prerequisites:** Docker with Compose support (e.g. [Docker Desktop](https://www.docker.com/products/docker-desktop/)).

### Option A: One-line setup (recommended)

No clone, no build, no file editing. Run the one-liner for your OS:

**Linux / macOS:**
```bash
bash <(curl -sSL https://raw.githubusercontent.com/simoneloru/docker-legioni/main/setup.sh)
```

**Windows PowerShell:**
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "iwr -UseBasicParsing https://raw.githubusercontent.com/simoneloru/docker-legioni/main/setup.ps1 | iex"
```

The script asks for your workspace path once, creates the minimal config, pulls the pre-built image, and prints the daily-use command.

After setup, every day you just run:

```bash
docker compose run --rm dev    # or: go, java, php
```

### Option B: Clone and build locally

Full control. Good if you want to customize the Dockerfile.

```bash
git clone https://github.com/simoneloru/docker-legioni.git
cd docker-legioni
cp .env.example .env
```

Edit `.env`, then build and run:

```bash
docker compose build                  # first time: 2-5 minutes
docker compose run --rm dev           # enter the container
```

You'll get a bash prompt. Your workspace is mounted at `/workspace`.

## Daily workflow

From inside the container:

```bash
cd /workspace/my-project              # navigate to your project
opencode                               # start coding with AI
```

For a new project:

```bash
cd /workspace/my-project
git init
legioni init                           # detect stack, write project config
legioni install                        # compile agents from roles + lessons
opencode
```

The first time you run `opencode`, it prompts you to configure an AI provider. The configuration persists in the `dev-config` volume.

> **Tip: second terminal.** Keep your `opencode` session running and open another terminal into the same container:
> ```bash
> docker exec -it --user dev $(docker ps -q -f name=dev) bash
> ```

## VS Code / Dev Containers

Open the `docker-legioni` folder in VS Code. When prompted "Reopen in Container", click yes. Or press `Ctrl+Shift+P` and run `Dev Containers: Reopen in Container`.

To change the stack, edit `service` in `.devcontainer/devcontainer.json` (`dev`, `go`, `java`, or `php`) and reopen.

Also works with [GitHub Codespaces](https://github.com/features/codespaces): open the repo on GitHub, click `Code → Codespaces → Create codespace on main`.

## Available stacks

All services share the same volumes (workspace, config, credentials). Pick the one that matches your stack:

```bash
docker compose run --rm dev    # Node + Python   (default)
docker compose run --rm go     # + Golang
docker compose run --rm java   # + JDK 21, Maven
docker compose run --rm php    # + PHP 8, Composer
```

| Service | Tag | Includes |
|---|---|---|
| `dev` | `dev` / `latest` | Node 20, Python 3, git, gh, opencode, legioni |
| `go` | `go` | dev + Go 1.26 |
| `java` | `java` | dev + JDK 21 Temurin, Maven |
| `php` | `php` | dev + PHP 8.3, Composer |

> Need a database? See [examples/](examples/) for MySQL (PHP) and PostgreSQL (Go, Java) overrides.

## Structure

```
docker-legioni/
├── compose.yaml             # service definition and bind mounts
├── Dockerfile               # Node 20 + git + python3 + opencode + legioni + gh
├── entrypoint.sh            # auto legioni install on first run
├── .env.example             # template for your local .env
├── .gitignore               # excludes .legioni/ and .env
├── package.json             # tracks opencode-ai version for Renovate
├── setup.ps1 / setup.sh     # setup helpers
└── .legioni/                # your team store (bind mount, not committed here)
    ├── roles/               # role definitions
    ├── lessons/             # accumulated agent experience
    └── config.json          # team configuration
```

### Persistence model

| Path | Type | Survives? |
|---|---|---|
| `.legioni/` | Bind mount (`./.legioni`) | Yes — lives on your disk |
| `~/.config/` | Named Docker volume (`dev-config`) | Yes — survives `docker compose down` |
| `/workspace/` | Bind mount | Yes — lives on your host disk |

**Why `.legioni/` is a bind mount, not a named volume:**

The team store (roles, lessons, config) is data, not config. Lessons grow over time — agents learn from every session. A bind mount lets you edit roles from your IDE, commit lessons to a private git repo, and never lose experience when rebuilding the image.

For full legioni documentation, see [github.com/simoneloru/legioni](https://github.com/simoneloru/legioni).

## Git configuration

Default: `Dev User <dev@localhost>`. Override via `.env`:

```env
GIT_USER_NAME=Your Name
GIT_USER_EMAIL=you@example.com
```

## Git authentication for private repos

`gh` is pre-installed and authentication persists inside the `dev-config` volume. You only authenticate once per host.

**GitHub** — use `gh` (recommended):
```bash
gh auth login
```

**Bitbucket Cloud** — create an API token first:
1. [Bitbucket settings → API tokens](https://bitbucket.org/account/settings/) → Create API token
2. Permissions: `repository:read`, `repository:write`
3. Then clone and enter your username + the API token (not your login password):
```bash
git clone https://bitbucket.org/your-workspace/your-repo.git
```

**Other hosts / manual** — the credential helper kicks in automatically:
```bash
git clone https://your-host.com/your-repo.git
# enter username + password/token when prompted — saved automatically
```

## Two-repo setup (recommended)

1. **This repo** (public) — Dockerfile, compose, entrypoint
2. **Private repo** — your team store, cloned into `.legioni/`

```bash
git clone git@github.com:your-username/legioni-team.git .legioni
```

`.legioni/` is already in `.gitignore` here.

## Updating pinned versions

The Dockerfile pins `legioni` and `gh` via `ARG`. `opencode` is tracked via `package.json`.

```dockerfile
ARG LEGIONI_VERSION=0.5.3
ARG GH_VERSION=2.95.0
```

Version updates are automated:
- **Renovate** watches `package.json` → opens PRs for `opencode-ai`
- **Renovate** checks npm and GitHub → opens PRs for `legioni` and `gh`

## Stop

```bash
docker compose down          # stops container, preserves dev-config volume
docker compose down -v       # stops AND deletes the volume
```

## Troubleshooting

### "/workspace is empty" or no files

The compose uses a fallback (`~/workspace`) if `WORKSPACE_PATH` is not set. Create `.env` and point `WORKSPACE_PATH` to your real projects folder. Make sure the directory exists — Docker may create an empty one if the path doesn't exist, which can be confusing.

### Container starts and exits immediately

Run `docker compose logs dev`. Common causes: missing `.env`, invalid `WORKSPACE_PATH`, or `entrypoint.sh` with CRLF line endings. If line endings are the issue, run:

```bash
git add --renormalize .
git commit -m "fix line endings"
```

### opencode says "no provider configured"

First launch: configure an AI provider. The settings save inside the `dev-config` volume.

### Permission denied (EACCES) on `/workspace`

On some systems (especially Windows with Docker Desktop), files created by one container session may have restrictive permissions for the `dev` user. The container includes passwordless `sudo` — prefix the command with `sudo`:

```bash
sudo legioni init
sudo rm -rf /workspace/my-project/.legioni    # clean up old scaffolding
sudo touch /workspace/my-project/test.txt     # any write operation
```

New project directories created by the current `dev` user (UID 1001) should work without `sudo`.

## License

MIT — see [LICENSE](LICENSE).
