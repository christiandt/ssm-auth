#!/usr/bin/env bash

shutdown() {
  echo "Initiating shutdown-procedure ..."
  ./shutdown.sh
}

trap shutdown 1 2 3 6

./ssm-auth.sh
amazon-ssm-agent &

tail -f /dev/null
