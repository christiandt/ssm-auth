#!/usr/bin/env bash

./ssm-auth.sh
amazon-ssm-agent &

tail -f /dev/null
