#!/bin/bash

echo "Starting service..."
echo "Timestamp: $(date)"
echo "PID: $$"

env

# loop to simulate a service doing work before erroring out
for i in {1..2}; do
  echo "$i: Example output: $RANDOM"
  sleep 1
done

echo "Exiting with an error"
exit 1
