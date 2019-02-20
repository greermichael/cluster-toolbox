#!/usr/bin/env bash

POOL_WAIT_SECONDS=15
MAX_ATTEMPTS=20
EXPECTED_NODES=3

iterator=0

while true; do
    if [[ ${iterator} -gt 0 ]]; then
        echo "Sleeping ${POOL_WAIT_SECONDS}"
        sleep ${POOL_WAIT_SECONDS}
    fi

    iterator=$((iterator+1))

    echo "Attempt ${iterator} of ${MAX_ATTEMPTS}"
    nodes=$(kubectl get nodes 2>&1)
    
    if [ "$?" -ne "0" ]; then
        echo "${nodes}"
        if [[ "${iterator}" -eq "${MAX_ATTEMPTS}" ]]; then
            exit 1
        else
            continue
        fi
    fi

    ready=$(echo -n "${nodes}" | grep '^.*Ready.*$' | wc -l)

    if [[ "${ready}" -lt "${EXPECTED_NODES}" ]]; then
        if [[ "${iterator}" -eq "${MAX_ATTEMPTS}" ]]; then
            echo "Only ${ready} are ready, expected ${EXPECTED_NODES}"
            exit 2
        else
            continue
        fi
    else
        echo "All ${ready} nodes are ready"
        exit 0
    fi

done