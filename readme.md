# Piston (Personal Edition)

A Docker-managed code execution engine for running untrusted code in a sandboxed environment. This edition is configured for personal deployments with automatic runtime installation on container startup.

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Node.js, when using the CLI directly from the host
- Cgroup v2 enabled for sandboxing
- x86_64 or ARM64 host architecture

### Installation

1. Clone the repository:
   ```sh
   git clone https://github.com/engineer-man/piston
   cd piston
   ```

2. Configure the environment:
   ```sh
   cp .env.example .env
   ```

   Edit `.env` to choose the API bind address, runtime packages, and optional API key. Runtime packages use `language` or `language=version`:
   ```env
   PISTON_INSTALL_PACKAGES=bash,python=3.12.0,node=20.11.1,gcc
   ```

3. Build the API image:
   ```sh
   docker-compose build api
   ```

4. Start Piston:
   ```sh
   docker-compose up -d
   ```

   The entrypoint installs packages listed in `PISTON_INSTALL_PACKAGES` after the API starts. Follow setup progress with:
   ```sh
   docker-compose logs -f api
   ```

## Usage

### Docker Commands

| Command | Description |
| :--- | :--- |
| `docker-compose up -d` | Start Piston in the background |
| `docker-compose down` | Stop and remove Piston containers |
| `docker-compose restart` | Restart Piston containers |
| `docker-compose logs -f api` | Follow API logs |
| `docker-compose exec api /bin/bash` | Open a shell in the API container |
| `docker-compose build api` | Rebuild the API image |

The helper script at `scripts/piston` wraps common Docker Compose commands:

```sh
scripts/piston start
scripts/piston logs
scripts/piston shell
scripts/piston list
```

### Managing Runtimes

List installed runtimes:

```sh
curl -s http://localhost:2000/api/v2/runtimes | jq -r '.[].language + " (" + .version + ")"'
```

List packages available from the configured package repository:

```sh
docker-compose exec -T api node core/cli/index.js ppman list --all
```

Install or uninstall a package:

```sh
docker-compose exec -T api node core/cli/index.js ppman install python=3.12.0
docker-compose exec -T api node core/cli/index.js ppman uninstall python=3.12.0
```

Available package recipes in this checkout:

| Language | Versions |
| :--- | :--- |
| bash | 5.1.0, 5.2.0 |
| gcc | 10.2.0 |
| go | 1.16.2 |
| java | 15.0.2 |
| node | 15.10.0, 16.3.0, 18.15.0, 20.11.1 |
| php | 8.0.2, 8.2.3 |
| python | 2.7.18, 3.5.10, 3.9.1, 3.9.4, 3.10.0-alpha.7, 3.10.0, 3.11.0, 3.12.0 |
| rust | 1.50.0, 1.56.1, 1.62.0, 1.63.0, 1.65.0, 1.68.2 |
| typescript | 4.2.3, 5.0.3 |

### Running Code Through the CLI

```sh
echo 'print("Hello from Piston!")' > test.py
docker-compose exec -T api node core/cli/index.js run python test.py -l 3.12.0
```

## API Reference

The Piston API listens on port `2000` by default.

### Execute Code

`POST /api/v2/execute`

```json
{
    "language": "python",
    "version": "3.12.0",
    "files": [
        {
            "name": "main.py",
            "content": "print('Hello, Piston!')"
        }
    ]
}
```

### Get Runtimes

`GET /api/v2/runtimes`

Returns installed languages and versions.

See [docs/api.md](docs/api.md) for the full API reference.

## Project Structure

- `core/api`: REST and WebSocket execution API.
- `core/cli`: CLI for executing code and managing packages.
- `core/repo`: Local package repository server tooling.
- `scripts`: Container entrypoint and management helpers.
- `packages`: Build recipes for language runtimes.
- `tests`: Security and regression tests.

Runtime data is created under `data/` by Docker Compose and is not tracked in git.

## Security And Authentication

Sandboxing is handled by Isolate inside Docker. Jobs run without networking by default and are constrained by CPU, memory, process, file, and output limits.

To require an API key, set `PISTON_KEY` in `.env`. Requests to mutating endpoints must include the same value in the `Authorization` header:

```sh
curl -H "Authorization: $PISTON_KEY" \
  -H "Content-Type: application/json" \
  -X POST http://localhost:2000/api/v2/execute \
  -d '{"language":"python","version":"3.12.0","files":[{"content":"print(42)"}]}'
```

The CLI also reads `PISTON_KEY` from the environment or `.piston_key` when present.

## ARM64 Notes

`docker-compose.yaml` defaults to the x86 image configuration:

```yaml
PISTON_PLATFORM=linux/amd64
PISTON_DOCKERFILE=Dockerfile.x86
```

For ARM64 experiments, set the platform and Dockerfile explicitly in `.env`:

```env
PISTON_PLATFORM=linux/arm64
PISTON_DOCKERFILE=Dockerfile.arm
```

The ARM Dockerfile uses the repository's mock Isolate implementation, so it is useful for local development but should not be treated as equivalent to the x86 sandbox.

## Troubleshooting

### `jq: parse error: Invalid numeric literal`

The API probably returned an error or plain text instead of JSON. Rebuild and restart the API, then check logs:

```sh
docker-compose build api
docker-compose up -d
docker-compose logs -f api
```

### Runtimes Not Showing Up

- Confirm `PISTON_INSTALL_PACKAGES` is set in `.env`.
- Use `language=version` when you need a specific runtime version.
- Check installation logs with `docker-compose logs -f api`.

---

Customized from the original [EngineerMan/Piston](https://github.com/engineer-man/piston).
