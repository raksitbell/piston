# Piston (Personal Edition)

A high-performance, general-purpose code execution engine, optimized for personal use and entirely managed via Docker. Piston allows you to run untrusted and potentially malicious code in a secure, sandboxed environment.

## 🚀 Getting Started

### Prerequisites

- **Docker & Docker Compose** (Required)
- **Cgroup v2** enabled (standard on most modern Linux distros and macOS)
- **Supported Architectures**: x86_64 and ARM64 (Apple Silicon).

### Installation

1. **Clone the repository:**
   ```sh
   git clone https://github.com/engineer-man/piston
   cd piston
   ```

2. **Configure your environment:**
   Copy the example environment file and edit it to your liking:
   ```sh
   cp .env.example .env
   ```
   Open `.env` and set your preferred port and the list of languages you want to install:
   ```env
   # Example: Install Python, Node.js, and GCC
   PISTON_INSTALL_PACKAGES=python,node,gcc
   ```

3. **Build the container image:** (Required for new setup)
   ```sh
   docker-compose build api
   ```

4. **Start Piston:**
   ```sh
   ./scripts/piston start
   ```
   *The container will automatically download and install the languages you've listed in `.env` on startup. Check the progress with `./scripts/piston logs`.*

---

## 🛠 Usage

### Management Utility (`./scripts/piston`)

A thin helper script is provided for common tasks:

| Command | Description |
| :--- | :--- |
| **`./scripts/piston start`** | Start Piston in the background using docker-compose. |
| **`./scripts/piston stop`** | Stop the service and remove containers. |
| **`./scripts/piston restart`** | Restart all Piston services. |
| **`./scripts/piston logs`** | View live logs (useful for monitoring language installation). |
| **`./scripts/piston list`** | List all currently installed and active language runtimes. |
| **`./scripts/piston update`**| Update the codebase and rebuild the container image. |
| **`./scripts/piston shell`** | Open a bash shell inside the API container. |

### Configuration (`.env`)

Piston is configured entirely through environment variables. Key options include:

- `PISTON_INSTALL_PACKAGES`: Comma-separated list of languages to auto-install (e.g., `python,node=20.11.1,bash`).
- `PORT`: The host port to map Piston API to (default: `2000`).
- `PISTON_LOG_LEVEL`: Set to `DEBUG` for detailed troubleshooting.

## 🌐 Documentation

- [**API Reference**](./docs/api.md): Detailed technical guide for REST and WebSocket endpoints.
- [**Changelog**](CHANGELOG.md): History of all notable changes and releases.

---

## 🗂 Project Structure

- `core/api`: The backend execution engine.
- `core/cli`: Internal CLI tool for automated package management.
- `core/repo`: Local package repository (optional configuration).
- `scripts/`: Management and internal setup scripts.
- `data/`: Persistent storage for installed packages and logs.
- `packages/`: Docker build recipes for custom language runtimes.
- `tests/`: Security and exploit resistance tests.

## 🛠 Troubleshooting

### `jq: parse error: Invalid numeric literal`
If you see this error when running `./scripts/piston list`, it means the API is not returning the expected JSON. This usually happens if:
1. **Stale Image**: You started the container without building it first. Run `docker-compose build api` then `./scripts/piston start`.
2. **Setup in Progress**: The container is still installing languages. Check the logs with `./scripts/piston logs`.

### Runtimes not showing up
If `./scripts/piston list` is empty:
- Ensure `PISTON_INSTALL_PACKAGES` is correctly set in your `.env`.
- Check logs for any installation errors.

## 🛡 Security

Piston uses [Isolate](https://www.ucw.cz/moe/isolate.1.html) inside Docker for robust sandboxing. It ensures:
- No outgoing network interaction by default.
- Resource limits (CPU, Memory, Processes).
- File system isolation and automatic cleanup.

---
*Customized from the original [EngineerMan/Piston](https://github.com/engineer-man/piston).*
