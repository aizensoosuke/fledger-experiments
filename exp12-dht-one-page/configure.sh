#!/bin/bash

### CENTRAL: flsignal
### N0-0: create pages
### N0-1: create realm
###
### ALL OTHER INSTANCES: fetch page

mkdir -p env.systemd

amount=$(grep -e "NODE_AMOUNT=" env | sed -e 's/NODE_AMOUNT=//')
pernode=$(grep -e "INSTANCES_PER_NODE=" env | sed -e 's/INSTANCES_PER_NODE=//')
malicious_percent=$(grep -e "MALICIOUS_PERCENT=" env | sed -e 's/MALICIOUS_PERCENT=//')
malicious_amount=$((amount * pernode * malicious_percent / 100))

for i in $(seq 0 $((amount - 1))); do
  node="n${i}"
  mkdir -p "env.systemd/$node"

  for j in $(seq 0 $((pernode - 1))); do
    instance="fledger-$node-$j"
    current_instance=$((i * pernode + j))
    cmd="--bootwait-max 3000 simulation fetch-page --timeout-ms 20000"
    if test $current_instance -le $malicious_amount; then
      cmd="--evil-noforward $cmd"
    fi

    envfile="env.systemd/$node/$instance"
    {
      echo "CENTRAL_HOST=10.0.128.128"
      echo "NODE_NAME=$instance"
      echo "NODE_CMD=$cmd"
      echo "RUST_BACKTRACE=full"
      echo "WAIT=true"
    } >"$envfile"
  done
done

create_page_cmd="--sampling-rate-ms 1000 simulation create-page-with-fillers --filler-amount 110 --page-size 5000 --settling-delay 5000" # corresponding flo size: 1911 B
create_realm_cmd="realm create simulation 100000 100000"

if test "$malicious_percent" = "100"; then
  create_page_cmd="--evil-noforward $create_page_cmd"
  create_realm_cmd="--evil-noforward $create_realm_cmd"
fi

# override fledger-n0-0
# it will create the tag
node=n0
j=0
instance="fledger-$node-$j"
envfile="env.systemd/$node/$instance"
{
  echo "CENTRAL_HOST=10.0.128.128"
  echo "NODE_NAME=$instance"
  echo "NODE_CMD=$create_page_cmd"
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
  # echo "NODE_CMD=realm create simulation 19000 5734" # 10 flos @ 1911 B => 19111 B /// 1 flo @ 1911 B (times 3 + 1) => 5734 B
  # flo sizes are kind of broken - experimentally 10 filler pages of size 512 B each go to around 17kB
  echo "NODE_CMD=$create_realm_cmd"
  echo "WAIT=false"
} >"$envfile"

{
  echo "FLSIGNAL=true"
  echo "FLREALM=false"
} >"env.systemd/central"
