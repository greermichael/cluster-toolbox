#!/usr/bin/env bash
if [ "$#" -eq 0 ]; then
    echo "Illegal number of parameters"
    exit 1
else
    expected=$1
fi
if [ "$#" -gt 1 ]; then
    POOL_WAIT_SECONDS=$2
else
    POOL_WAIT_SECONDS=10
fi
if [ "$#" -eq 3 ]; then
    MAX_ATTEMPTS=$3
else
    MAX_ATTEMPTS=18
fi

echo "Initializing Nodes Ready check ...."
sleep ${POOL_WAIT_SECONDS}
nodes=$(kubectl get nodes 2>&1)
#nodes=$(cat nodes.txt)  # for internal testing 
spunup=$(echo -n "${nodes}" | grep -v 'NAME' | wc -l)
nodes=

if [ $spunup -gt $expected ]; then
    echo "Error: expected: $expected, but $spunup nodes are started..."
    exit 1
fi

iterator=0
echo "Checking if all requested worker nodes are reporting 'Ready'..."
while true; do
    if [[ ${iterator} -gt 0 ]]; then
        sleep ${POOL_WAIT_SECONDS}
    fi

    iterator=$((iterator+1))

    nodes=$(kubectl get nodes 2>&1)
#    nodes=$(cat nodes.txt)    # for internal testing  
    if [ "$?" -ne "0" ]; then
        echo "${nodes}"
        if [[ "${iterator}" -eq "${MAX_ATTEMPTS}" ]]; then
            exit 1
        else
            continue
        fi
    fi

    ready=$(echo -n "${nodes}" | grep ' Ready' | wc -l)

    if [[ "${ready}" -lt "${expected}" ]]; then
        echo "Attempt ${iterator} of ${MAX_ATTEMPTS} [${POOL_WAIT_SECONDS}s interval]: ${ready} out of ${expected} are READY."
        if [[ "${iterator}" -eq "${MAX_ATTEMPTS}" ]]; then
            echo "ERROR: Only ${ready} are ready, expected ${expected}"
            exit 2
        else
            continue
        fi
    else
        echo "All ${expected} nodes are ready"
        exit 0
    fi

done
