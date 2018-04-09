#!/bin/bash

echo "### Starting automated Rundeck setup... ###"

rdeck_home=${RDECK_BASE:-/var/lib/rundeck}
rdeck_config=${RDECK_CONFIG:-/etc/rundeck}
profile=${RDECK_CONFIG}/profile
lock_file=${rdeck_home}/.entrypoint.lock

while [ ! -f ${profile} ]; do
    echo "Rundeck is being installed. Waiting till it finishes..."
    sleep 2
done

if [ ! -f $lock_file ]; then
    echo "  # Creating Rundeck directories..."
    mkdir -v -p "${rdeck_config}"/ssl  "${rdeck_config}"/keys "${rdeck_home}"/jumia_scripts /tmp/rundeck
    echo "  # Rundeck directories created."

    echo "  # Setting permissions and ownership..."
    chown -R rundeck: "${rdeck_config}" "${rdeck_home}"
    chown -R 750 "${rdeck_config}"
    echo "  # All permissions and ownership set up."

    echo "  # Downloading default plugins..."

    echo "  # Default plugins downloaded."

    echo "  # Creating lock to avoid execution of unnecessary steps..."
    touch ${rdeck_home}/.entrypoint.lock
    echo "  # Lock created."
else
    echo "This is an upgrade of an existing version of Rundeck..."
fi

echo "### Rundeck setup finished! ###"

exit 0
