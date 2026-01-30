#!/usr/bin/env bash
set -e

echo "OpenClaw entrypoint starting"

PORT="${PORT:-8080}"
STATE_DIR="${OPENCLAW_STATE_DIR:-/data/.openclaw}"
WORK_DIR="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}"

mkdir -p "$STATE_DIR" "$WORK_DIR"

echo "State dir: $STATE_DIR"
echo "Workspace dir: $WORK_DIR"
echo "Port: $PORT"

exec node dist/index.js
