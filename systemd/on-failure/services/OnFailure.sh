#!/bin/bash

UNIT="OneShot.service"
NUM_LINES="100"

SYSTEMD_VERSION=$(systemctl --version | head -1 | awk '{ print $2}')

# Systemd did not begin setting monitor environment variables until
# version 251.
if [[ "$SYSTEMD_VERSION" -lt 251 ]]; then
  # Instead, we can grab the last n lines of all invocations of the
  # service that failed. This has the potential to include logs from
  # concurrent invocations of the service (e.g. laravel's scheduler
  # that runs every minute). This is not ideal, but should be able to
  # provide sufficient information to debug the issue.
  LOGS=$(
    journalctl \
      _SYSTEMD_UNIT=$UNIT \
      --lines "$NUM_LINES" \
      --output cat \
      --no-pager
  )
else
  # Using the invocation ID of the failed service, we can get the logs
  # of the specific service that failed (without grabbing logs from any
  # other invocations that might have happened previously).
  LOGS=$(
    journalctl \
      _SYSTEMD_INVOCATION_ID="$MONITOR_INVOCATION_ID" \
      --lines "$NUM_LINES" \
      --output cat \
      --no-pager
  )
fi

echo "$LOGS" > /tmp/a
