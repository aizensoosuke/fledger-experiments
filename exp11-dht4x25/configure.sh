#!/bin/bash

mkdir -p env.systemd

amount=100

for i in $(seq 0 $((amount - 1))); do
  nodename="n${i}"

  mkdir -p "env.systemd/$nodename"
  envfile="env.systemd/${nodename}/fledger-${nodename}-0"

  centralhost="10.0.128.128"

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
