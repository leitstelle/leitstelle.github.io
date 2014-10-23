#!/usr/bin/env bash
ls -al --color
id
ip

PORT=64683

if [[ -z $(netstat -tulpen | grep ${PORT}) ]]; then
    echo "Your choosen \$PORT is available."
else
    echo "Your choosen \$PORT is not available. Choose another. Aborting the script!"
    exit 2
fi
