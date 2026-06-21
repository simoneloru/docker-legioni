# Examples

Extended stacks built on top of `docker-legioni`. Each example shows how to add
a database service alongside the dev container.

## Usage

Every example follows the same pattern — start the database first, then run the dev container:

```bash
# 1. Start the database
docker compose -f compose.yaml -f examples/STACK/override.yaml up -d db

# 2. Enter the dev container (database stays running)
docker compose -f compose.yaml -f examples/STACK/override.yaml run --rm <service>
```

Replace `STACK` and `<service>` with the example name and service from the table below.

## Available stacks

| Example | Service | Database |
|---|---|---|
| `php-mysql` | `php` | MySQL 8 |
| `go-postgres` | `go` | PostgreSQL 16 |
| `java-postgres` | `java` | PostgreSQL 16 |
