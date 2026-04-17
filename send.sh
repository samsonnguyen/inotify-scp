#!/usr/bin/env bash
set -euo pipefail

timestamp="$1"; shift
target="$1"; shift
event="$1"; shift
file="$1"; shift

: "${IDENTITY_FILE:?IDENTITY_FILE must be set}"
: "${DESTINATION:?DESTINATION must be set}"

path="${target}${file}"

log() { echo "[${timestamp}] ${file} (${event}): $*"; }

case "${event}" in
  *CLOSE_WRITE*|*MOVED_TO*) ;;
  *)
    log "ignoring event"
    exit 0
    ;;
esac

if [ ! -f "${path}" ]; then
  log "file no longer exists, skipping"
  exit 0
fi

max_attempts=5
attempt=1
delay=2

while : ; do
  log "sending (attempt ${attempt}/${max_attempts})"
  if scp -o StrictHostKeyChecking=accept-new \
         -o ConnectTimeout=10 \
         -i "${IDENTITY_FILE}" \
         "${path}" "${DESTINATION}"; then
    rm -f "${path}"
    log "sent successfully"
    exit 0
  fi

  if [ "${attempt}" -ge "${max_attempts}" ]; then
    log "send failed after ${max_attempts} attempts, leaving file in place"
    exit 1
  fi

  log "send failed, retrying in ${delay}s"
  sleep "${delay}"
  attempt=$((attempt + 1))
  delay=$((delay * 2))
done
