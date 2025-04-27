#!/bin/bash

mkdir -p env.systemd

amount=$(grep -e "NODE_AMOUNT=" env | sed -e 's/NODE_AMOUNT=//')
pernode=$(grep -e "INSTANCES_PER_NODE=" env | sed -e 's/INSTANCES_PER_NODE=//')

tag="tag-$(openssl rand -hex 4)"

for i in $(seq 0 $((amount - 1))); do
  node="n${i}"
  mkdir -p "env.systemd/$node"

  for j in $(seq 0 $((pernode - 1))); do
    instance="fledger-$node-$j"
    envfile="env.systemd/$node/$instance"
    {
      echo "CENTRAL_HOST=10.0.128.128"
      echo "NODE_NAME=$instance"
      echo "NODE_CMD=--bootwait-max 10000 simulation fetch-tag --tag $tag"
      echo "RUST_BACKTRACE=full"
      echo "WAIT=true"
    } >"$envfile"
  done
done

# override fledger-n0-0
# it will create the tag
node=n0
j=0
instance="fledger-$node-$j"
envfile="env.systemd/$node/$instance"
{
  echo "CENTRAL_HOST=10.0.128.128"
  echo "NODE_NAME=$instance"
  echo "NODE_CMD=simulation create-tag --tag $tag"
  echo "WAIT=false"
} >"$envfile"

# override fledger-n0-1
# it will create the realm
node=n0
j=1
instance="fledger-$node-$j"
envfile="env.systemd/$node/$instance"
{
  echo "CENTRAL_HOST=10.0.128.128"
  echo "NODE_NAME=$instance"
  echo "NODE_CMD=realm create 65535 65535"
  echo "WAIT=false"
} >"$envfile"

{
  echo "FLSIGNAL=true"
  echo "FLREALM=false"
} >"env.systemd/central"
