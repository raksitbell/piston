# Piston API Reference (v2)

This document describes the REST and WebSocket API exposed by the Piston execution engine.

## Authentication

If `PISTON_KEY` is set, every API request must include the same value in the `Authorization` header:

```sh
Authorization: your-secret-key
```

When `PISTON_KEY` is not set, the API does not require authentication.

## Code Execution

### Execute Code

Run code in a sandboxed environment.

**Endpoint:** `POST /api/v2/execute`

**Request body:**

```json
{
    "language": "python",
    "version": "3.12.0",
    "files": [
        {
            "name": "main.py",
            "content": "print('Hello, Piston!')"
        }
    ],
    "stdin": "",
    "args": ["arg1"],
    "compile_timeout": 10000,
    "run_timeout": 3000,
    "compile_memory_limit": -1,
    "run_memory_limit": -1,
    "compile_cpu_time": 10000,
    "run_cpu_time": 3000
}
```

`language`, `version`, and `files` are required. The version can be an exact version or another semver selector supported by the runtime resolver, such as `*`.

**Successful response:**

```json
{
    "language": "python",
    "version": "3.12.0",
    "run": {
        "stdout": "Hello, Piston!\n",
        "stderr": "",
        "code": 0,
        "signal": null,
        "output": "Hello, Piston!\n"
    }
}
```

Compiled languages may also include a `compile` object with the same output shape.

### Connect

Run an interactive job over WebSocket.

**Endpoint:** `WS /api/v2/connect`

Message flow:

1. Send an `init` message with the same job fields accepted by `POST /api/v2/execute`, plus `"type": "init"`.
2. Receive `runtime`, `stage`, `data`, and `exit` messages while the job runs.
3. Send `data` messages with `"stream": "stdin"` to provide input.
4. Send `signal` messages to forward supported process signals.

The socket closes if it is not initialized within one second.

## Runtime Management

### List Runtimes

Get currently installed runtimes.

**Endpoint:** `GET /api/v2/runtimes`

**Response:**

```json
[
    {
        "language": "python",
        "version": "3.12.0",
        "aliases": ["py", "python3"],
        "runtime": "cpython"
    }
]
```

### List Available Packages

Get packages that can be installed from the configured repository index.

**Endpoint:** `GET /api/v2/packages`

**Response:**

```json
[
    {
        "language": "python",
        "language_version": "3.12.0",
        "installed": true
    }
]
```

### Install Package

Download and install a package.

**Endpoint:** `POST /api/v2/packages`

**Body:**

```json
{
    "language": "python",
    "version": "3.12.0"
}
```

### Uninstall Package

Remove an installed package.

**Endpoint:** `DELETE /api/v2/packages`

**Body:**

```json
{
    "language": "python",
    "version": "3.12.0"
}
```

---

[Back to Main Readme](../readme.md)
