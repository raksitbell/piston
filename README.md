# CodeArea executor

This vendored Piston runtime executes learner code on a separate Windows Desktop through Docker Desktop. The CodeArea application uses only Piston's native `POST /api/v2/execute` interface at `http://<windows-host>:2000`.

The repository contains only the Piston API, its package-management CLI, the Isolate-based image, and deployment configuration. Runtime package sources, repository builders, ARM mock isolation, historical tests, tracked secrets, and unrelated maintenance files were removed.

## Initialize

Open PowerShell in `utils/executor`:

```powershell
Copy-Item .env.example .env
docker compose up -d --build
docker compose ps
```

The initial startup installs four Piston packages. Piston package names differ from some exposed language names:

- `node=18.15.0` exposes JavaScript `18.15.0`
- Python `3.10.0`
- `gcc=10.2.0` exposes C++ `10.2.0`
- Java `15.0.2`

Installed runtimes and Piston data persist in named Docker volumes.

Configure the root application with:

```dotenv
PISTON_URL=http://windows-host:2000
PISTON_LANGUAGES=javascript:18.15.0,python:3.10.0,c++:10.2.0,java:15.0.2
```

Verify connectivity from the CodeArea host:

```bash
curl http://windows-host:2000/api/v2/runtimes
```

Piston runs privileged because Isolate and cgroup v2 require it. Keep the utility on a dedicated machine, disable job networking, restrict inbound TCP `2000` to the CodeArea host on a private LAN or VPN, and never expose it directly to the public internet.

The retained Piston implementation is derived from [Engineer Man's Piston](https://github.com/engineer-man/piston) under the included `LICENSE.txt` MIT license.
