#!/bin/sh

RDECK_PROFILE="/etc/rundeck/profile"
RETRIES=10

i=0
while [ $i -lt $RETRIES ]; do
    if [ -f $RDECK_PROFILE ]; then
        . ${RDECK_PROFILE}
        break
    fi
    i=$((i++))
    sleep $i
done

exec $rundeckd
