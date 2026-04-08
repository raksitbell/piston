# Piston (Personal Edition)

A high-performance, general-purpose code execution engine, optimized for personal use and entirely managed via Docker. Piston allows you to run untrusted and potentially malicious code in a secure, sandboxed environment.

## 🚀 Getting Started

### Prerequisites

- Docker & Docker Compose
- Node.js (for the CLI)
- Cgroup v2 enabled (for sandboxing)
- **Supported Architectures**: x86_64 (Intel/AMD) and ARM64 (Apple Silicon/M-series).

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
| **`./piston setup`** | **(Recommended)** Interactive wizard for building and installing languages. |
| **`./piston list`** | List all currently installed and active language packages. |
| **`./piston list --all`** | List every package available in the repository index. |
| **`./piston install <pkg>`**| Install a pre-built package from the repository. |
| **`./piston uninstall <pkg>`** | Remove a language package (cleanly hides it from the list). |
| **`./piston sync`** | Synchronize your fork with the original upstream repository. |
| **`./piston start / stop`** | Start or stop the Piston API Docker containers. |
| **`./piston restart`** | Restart the Piston environment. |
| **`./piston logs`** | View live logs from the API and repository services. |

### CLI (`core/cli/index.js`)

You can also interact with the CLI directly via the helper script for more advanced usage:

```sh
# Run a script immediately
echo 'print("Hello from Piston!")' > test.py
./piston run python test.py
```

## 🌐 API Reference

The Piston API is exposed on port **2000** by default.

### Execute Code
`POST /api/v2/execute`

**Request Body:**
```json
{
    "language": "python",
    "version": "3.10.0",
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

Returns a list of installed languages and versions.

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

## 🛡 Security & Authentication

Piston includes an automated system to secure your API access.

1.  **Generate a Key**:
    ```bash
    ./piston key generate
    ```
    This creates a random 32-character key and saves it to `.piston_key`.

2.  **Zero-Config Usage**:
    - The **CLI** and the **`./piston`** script automatically discover and use `.piston_key`.
    - The **API Service** picks up the key from the environment via Docker Compose automatically.

3.  **Manual API Calls**:
    Run `./piston key show` to get your key and a pre-formatted `curl` example:
    ```bash
    curl -H "Authorization: YOUR_KEY_HERE" -X POST ...
    ```

## 🍎 Native ARM64 (Apple Silicon) Support

This edition of Piston is optimized for **ARM64 (M1/M2/M3)**. If you see architecture-related errors (like `qemu-x86_64`), ensure your services and runtimes are built natively:

```bash
# Rebuild the Docker containers natively
./piston rebuild

# Rebuild all installed language packages natively
./piston rebuild-all
```

Piston uses [Isolate](https://www.ucw.cz/moe/isolate.1.html) inside Docker for robust sandboxing. It ensures:
- No outgoing network interaction by default.
- Resource limits (CPU, Memory, Processes).
- File system isolation and automatic cleanup.

---
*Customized from the original [EngineerMan/Piston](https://github.com/engineer-man/piston).*