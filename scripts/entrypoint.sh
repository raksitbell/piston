#!/usr/bin/env bash
set -Eeuo pipefail

readonly CGROUP_FS="/sys/fs/cgroup"

if [[ ! -d "$CGROUP_FS" ]]; then
    echo "[Piston] cgroup v2 is unavailable at $CGROUP_FS." >&2
    exit 1
fi

if [[ ! -d "$CGROUP_FS/isolate" ]]; then
    echo "[Piston] Initializing cgroup v2 for Isolate..."
    cd "$CGROUP_FS"
    mkdir -p isolate
    echo 1 > isolate/cgroup.procs
    echo "+cpuset +cpu +io +memory +pids" > cgroup.subtree_control
    cd isolate
    mkdir -p init
    echo 1 > init/cgroup.procs
    echo "+cpuset +memory" > cgroup.subtree_control
fi

mkdir -p /piston/packages /piston/data
chown -R piston:piston /piston/packages /piston/data

if [[ -n "${PISTON_INSTALL_PACKAGES:-}" ]]; then
    IFS=',' read -ra packages <<< "$PISTON_INSTALL_PACKAGES"
    for package in "${packages[@]}"; do
        echo "[Piston] Ensuring runtime is installed: $package"
        runuser -u piston -- node /piston/core/cli/install.js "$package"
    done
fi

cd /piston/core/api
su piston -c "ulimit -n 65536 && exec node src/index.js" &
api_pid=$!
trap 'kill "$api_pid" 2>/dev/null || true' EXIT INT TERM

echo "[Piston] Ready on port 2000."
wait "$api_pid"
