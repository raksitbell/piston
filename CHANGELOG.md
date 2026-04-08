# Changelog

- [**Readme**](./readme.md) | [**API Documentation**](./docs/api.md)

---

### Added
- **Docker-Centric Architecture**: Consolidated the API and CLI into a single root `Dockerfile`.
- **Automated Language Selection**: New `PISTON_INSTALL_PACKAGES` environment variable in `.env` for auto-installing languages on startup.
- **Unified Configuration**: All settings are now managed via a single `.env` file.
- **Modernized Helper Script**: Replaced complex setup scripts with a minimal, thin wrapper `./piston` for `docker-compose`.

### Changed
- **Documentation**: Fully redesigned `readme.md` to focus on the new Docker-only workflow.
- **Simplification**: Removed legacy scripts and redundant internal Dockerfiles.
- **Project Structure**: Organized all management and internal scripts into a dedicated [`scripts/`](file:///Users/raksit/Documents/piston/scripts/) directory.

### Fixed
- **Installation Friction**: Eliminated the need for manual/interactive setup steps.

## [2.1.0] - 2026-04-05

### Added
- **API Key Authentication**: Support for securing the API via the `PISTON_KEY` environment variable and `Authorization` header.
- **Upstream Synchronization**: New `./piston sync` command to safely rebase your personal fork on top of `engineer-man/piston`.
- **Interactive Setup Wizard**: New `./piston setup` command to easily select, build, and install language packages.
- **Management Shorthands**:
  - `./piston list`: View installed packages (filtered to only show active ones).
  - `./piston list --all`: View all available packages in the repository.
  - `./piston install <package>`: Install a pre-built package.
  - `./piston uninstall <package>`: Remove an installed package.
- **Native Windows Support**: Added `piston.ps1` PowerShell management script for a first-class experience on x86 Windows.
- **Improved Windows Documentation**: Added native installation instructions for Windows users.
- **Multi-Platform Support**: Build scripts now automatically detect and use the correct architecture (`x64` or `arm64`), enabling support for Apple Silicon Macs and regular Intel/AMD servers.

### Changed
- **OS Migration**: Updated base Docker images from Debian Buster (EOL) to **Debian Bullseye (11)**.
- **Node.js Migration**: Updated API and build environment to **Node.js 16** for better stability.
- **Setup Transparency**: `./piston setup` now provides real-time progress and error reporting during builds.

### Fixed
- **Build Errors**: Resolved 404 errors during `apt-get update` caused by Debian Buster reaching end-of-life.
- **Indexing Bug**: Corrected directory pathing in `mkindex.sh` to ensure built packages are correctly registered.
- **Portable Parsing**: Replaced incompatible `grep` flags with `sed` for across-the-board compatibility with macOS and Linux shells.
- **Shell Stability**: Fixed unclosed quote and EOF syntax errors in the `./piston` management script for older Bash versions (Bash 3.2).
