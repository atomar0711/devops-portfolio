#!/usr/bin/env bash
# /opt/myapp/heartbeat.sh: prints the configured message every 10 seconds
CONF=/etc/myapp/app.conf
while true; do
  if ! msg=$(cat "$CONF"); then
    echo "cannot read $CONF" >&2
    exit 1
  fi
  echo "$(date -Is) heartbeat: $msg"
  sleep 10
done
