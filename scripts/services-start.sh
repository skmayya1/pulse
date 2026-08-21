#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dev_root="$project_root/.dev"
postgres_root="$dev_root/postgres"
redis_root="$dev_root/redis"
postgres_log="$postgres_root/server.log"
redis_log="$redis_root/redis.log"
redis_pid="$redis_root/redis.pid"

mkdir -p "$dev_root" "$redis_root"

if pg_isready -q; then
  echo "PostgreSQL already running."
else
  if [ ! -f "$postgres_root/PG_VERSION" ]; then
    echo "Initializing PostgreSQL data directory at $postgres_root"
    initdb --pgdata="$postgres_root" --username="$(id -un)" --auth=trust
  fi

  echo "Starting PostgreSQL (logs: $postgres_log)"
  pg_ctl --pgdata="$postgres_root" --log="$postgres_log" --wait start
fi

if redis-cli ping >/dev/null 2>&1; then
  echo "Redis already running."
else
  echo "Starting Redis (logs: $redis_log)"
  redis-server --daemonize yes --dir "$redis_root" --dbfilename dump.rdb --logfile "$redis_log" --pidfile "$redis_pid"
fi

pg_isready
redis-cli ping
