#!/bin/bash

mkdir -p env.systemd

amount=100

for i in $(seq 0 $((amount - 1))); do
  nodename="n${i}"

  mkdir -p "env.systemd/$nodename"
  envfile="env.systemd/${nodename}/fledger-${nodename}-0"

  if test "$i" -lt 25; then
    centralhost="10.0.0.128"
  else
    centralhost="10.0.1.128"
  fi

  {
    echo "CENTRAL_HOST=$centralhost"
    echo "NODE_NAME=fledger-${nodename}-0"
    echo "NODE_CMD=--bootwait-max 15000 simulation dht-join-realm"
    echo "WAIT=true"
  } >"$envfile"
done

{
  echo "FLSIGNAL=true"
  echo "FLREALM=true"
} >"env.systemd/central"
