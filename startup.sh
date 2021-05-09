#!/usr/bin/env bash

trap ./shutdown.sh SIGINT SIGTERM SIGHUP ERR EXIT

./ssm-auth.sh
amazon-ssm-agent &

while true; do
    sleep 3600 & wait ${!}
done
