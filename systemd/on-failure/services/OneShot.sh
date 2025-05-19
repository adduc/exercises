#!/bin/bash

echo "Starting service..."
echo "Timestamp: $(date)"
echo "PID: $$"

env

# for 1 to 5
for i in {1..2}; do
  echo "$i: Example output: $RANDOM"
  sleep 1
done

echo "Exiting with an error"
exit 1
