# Changelog

All notable changes to this project will be documented in this file.

## [3.1.2] - 2026-04-08

### Fixed
- **Cross-Platform Compatibility**: Resolved the `/usr/bin/env: 'bash\r': No such file or directory` error by normalizing all shell and management scripts to Unix line endings (**LF**).
- **Line Ending Persistence**: Added a `.gitattributes` file to ensure shell scripts keep LF endings regardless of the operating system or Git configuration (e.g., Windows `core.autocrlf`).

### Changed
- **Docker Structure Improvements**: Migrated the internal container entrypoint to `core/api/entrypoint.sh` and removed the redundant `scripts/` directory, moving towards more standard Docker patterns.
- **Improved Ignore Patterns**: Updated `.gitignore` to better handle Node.js artifacts, OS-specific files, and persistent package indices.

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
