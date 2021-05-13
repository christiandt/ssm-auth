#!/usr/bin/env bash

DONE=0

trap './shutdown.sh && DONE=1' SIGTERM SIGKILL

./ssm-auth.sh connect
amazon-ssm-agent &

while [[ ${DONE} = 0 ]]; do
    sleep 3600 & wait ${!}
done

exit 0
