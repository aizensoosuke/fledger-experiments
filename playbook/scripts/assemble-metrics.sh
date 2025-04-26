#!/bin/bash

instances=$(ls ~/env.systemd)
node=$(hostname | sed -e 's/\..*//')
assembledmetrics="$HOME/$node.metrics"

if test -z "$instances"; then
  echo "WARNING: no instances!"
  exit
fi

echo "[gather metrics]"
touch "$assembledmetrics" || exit 1

for instance in $instances; do
  echo "$instance"
  instancemetrics="/tmp/$instance.metrics"

  if ! test -f "$instancemetrics"; then
    echo "WARNING: metrics file not found ($instancemetrics)"
  else
    cat "$instancemetrics" >>"$assembledmetrics" || exit 1
  fi
done
