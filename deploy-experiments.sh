#!/bin/bash

if test "$#" -ne 0; then
  echo "usage: $0"
  exit 1
fi

echo "Rsyncing experiment files..."
rsync -avh --delete --exclude ".*" --exclude "metrics" --exclude "*.metrics" --info=progress2 ./ fledger:~/experiments/
