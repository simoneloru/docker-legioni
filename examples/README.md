# Examples

Ready-to-use stacks built on top of `docker-legioni`. Each adds a database
service alongside the dev container, with persistent storage.

## Usage

Every stack uses the same two-step pattern:

```bash
# 1. Start the database (runs in background)
docker compose -f compose.yaml -f examples/STACK/override.yaml up -d db

# 2. Enter the dev container
docker compose -f compose.yaml -f examples/STACK/override.yaml run --rm <service>

# 3. When done, stop the database
docker compose -f compose.yaml -f examples/STACK/override.yaml down
```

Example for PHP + MySQL:

```bash
docker compose -f compose.yaml -f examples/php-mysql/override.yaml up -d db
docker compose -f compose.yaml -f examples/php-mysql/override.yaml run --rm php
```

Inside the container, connect to the database using hostname `db`:

```php
$pdo = new PDO('mysql:host=db;dbname=app', 'root', 'dev');
```

```go
db, _ := sql.Open("pgx", "postgres://dev:dev@db:5432/app")
```

```java
// JDBC URL: jdbc:postgresql://db:5432/app
```


## Available stacks

| Example | Service | Database |
|---|---|---|
| `php-mysql` | `php` | MySQL 8 |
| `go-postgres` | `go` | PostgreSQL 16 |
| `java-postgres` | `java` | PostgreSQL 16 |
