#!/usr/bin/env bash
# wait-for-it.sh: Wait for a service to be available before executing a command

set -e

host="$1"
shift
cmd="$@"

until nc -z -v -w30 ${host//:/ }; do
  echo "Waiting for $host..."
  sleep 1
done

echo "$host is available, executing command"
exec $cmd
