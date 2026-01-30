#!/usr/bin/env bash
set -euo pipefail

# Railway provides PORT; fall back for local testing
PORT="${PORT:-8080}"

STATE_DIR="${OPENCLAW_STATE_DIR:-/data/.openclaw}"
WORK_DIR="${OPENCLAW_WORKSPACE_DIR:-/data/workspace}"
CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-$STATE_DIR/openclaw.json}"

mkdir -p "$STATE_DIR" "$WORK_DIR"

# Seed config on first boot
if [ ! -f "$CONFIG_PATH" ]; then
  echo "Seeding OpenClaw config at: $CONFIG_PATH"

  # Minimal baseline config. No secrets hardcoded.
  # You will likely need to adjust keys once you confirm schema.
  cat > "$CONFIG_PATH" <<'JSON'
{
  "workspace": {
    "path": "__WORKSPACE_PATH__"
  },
  "channels": {
    "discord": {
      "enabled": true,
      "dm": {
        "policy": "pairing"
      }
    }
  }
}
JSON

  # Insert workspace path
  # (Linux-safe replacement)
  sed -i "s|__WORKSPACE_PATH__|$WORK_DIR|g" "$CONFIG_PATH"
fi

# Inject secrets at runtime if your schema supports it.
# If OpenClaw expects tokens in config, we write them in.
# This avoids committing tokens anywhere.
if [ -n "${DISCORD_BOT_TOKEN:-}" ]; then
  # This assumes a config key path like channels.discord.botToken.
  # If schema differs, we’ll adjust after first successful boot.
  node - <<'NODE'
const fs = require("fs");
const path = process.env.OPENCLAW_CONFIG_PATH || ((process.env.OPENCLAW_STATE_DIR || "/data/.openclaw") + "/openclaw.json");
const token = process.env.DISCORD_BOT_TOKEN;

const cfg = JSON.parse(fs.readFileSync(path, "utf8"));
cfg.channels = cfg.channels || {};
cfg.channels.discord = cfg.channels.discord || {};
cfg.channels.discord.botToken = token;

fs.writeFileSync(path, JSON.stringify(cfg, null, 2));
console.log("Injected Discord token into config:", path);
NODE
fi

# Start the gateway explicitly (don’t rely on “node dist/index.js” defaulting correctly)
echo "Starting OpenClaw gateway on 0.0.0.0:${PORT}"
exec node dist/index.js gateway --port "$PORT" --host 0.0.0.0 --verbose
