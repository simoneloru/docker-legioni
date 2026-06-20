# opencode + legioni Docker Dev Environment

[![Build](https://github.com/simoneloru/docker-legioni/actions/workflows/build.yml/badge.svg)](https://github.com/simoneloru/docker-legioni/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-simoneloru%2Fdocker--legioni-blue)](https://hub.docker.com/r/simoneloru/docker-legioni)

Run [opencode](https://opencode.ai) and [legioni](https://github.com/simoneloru/legioni) in a Docker container with full toolchain support, while keeping your projects on your host filesystem.

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
docker compose run --rm dev
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

## Structure

```
docker-legioni/
├── compose.yaml             # service definition and bind mounts
├── Dockerfile               # Node 20 + git + python3 + opencode + legioni + gh
├── entrypoint.sh            # auto legioni install on first run
├── .env.example             # template for your local .env
├── .gitignore               # excludes .legioni/ and .env
├── package.json             # tracks opencode-ai version for Dependabot
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

## GitHub CLI

`gh` is pre-installed. Authenticate once:

```bash
gh auth login
```

The token is saved in `~/.config/gh/` and persists across container restarts.

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
- **Dependabot** watches `package.json` → opens PRs for `opencode-ai`
- **Weekly workflow** checks npm and GitHub → opens PRs for `legioni` and `gh`

## Stop

```bash
docker compose down          # stops container, preserves dev-config volume
docker compose down -v       # stops AND deletes the volume
```

## Troubleshooting

### "/workspace is empty"

The container started but `/workspace` has no files. The compose uses a fallback (`~/workspace`) if `WORKSPACE_PATH` is not set — create `.env` and set it to your real projects folder.

### Container starts and exits immediately

Run `docker logs opencode-dev`. Common causes: missing `.env`, invalid `WORKSPACE_PATH`, or `entrypoint.sh` with CRLF line endings. If line endings are the issue, run:

```bash
git add --renormalize .
git commit -m "fix line endings"
```

### No files in `/workspace`

Check that `WORKSPACE_PATH` points to an existing directory. Docker may create it if it doesn't exist, which can be confusing.

### opencode says "no provider configured"

First launch: configure an AI provider. The settings save inside the `dev-config` volume.

### Permission errors on `.legioni/`

Bind mounts from the host may show odd permissions inside the container, but read/write should work for the `dev` user.

## License

MIT — see [LICENSE](LICENSE).
