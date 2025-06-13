#!/bin/bash

set -euo pipefail

function get_env {
  name="$1"
  env_file="./env"
  if test "$#" -gt 1; then
    env_file="$2"
  fi
  value=$(grep -e "$name=" "$env_file" | sed -e "s/$name=//")
  echo "$value"
}

function print_usage {
  echo "usage: $1 network_name vm_amount bots_per_vm"
  echo
  echo "example:"
  echo "$1 net33 33 3"
}

if test "$#" -lt 3; then
  print_usage "$0"
  exit 1
fi

net_name="$1"
vm_amount="$2"
bots_per_vm="$3"
hermes_url=$(get_env HERMES_URL)
hermes_token=$(get_env HERMES_TOKEN)

function check_usage {
  if test -z "$net_name" || test -z "$vm_amount" || test -z "$bots_per_vm"; then
    print_usage $0
    exit 1
  fi
}

function deploy_network {
  ./deploy-network.sh "networks/$net_name" || true
}

function hermes_request {
  method="$1"
  url="$2"
  data="$3"

  curl -X "$method" "$url" \
    -H "Authorization: Bearer $hermes_token" \
    -H 'Accept: application/json' \
    -d "$data"
}

function hermes_post {
  hermes_request POST "$1" "$2"
}

function hermes_get {
  hermes_request GET "$1" "$2"
}

# hermes is the api / dashboard / command and control center
# sets the experiment id in the experiment environment
function hermes_create_fleet {
  hermes_post \
    "$hermes_url/api/fleets" \
    "" |
    jq -r '.id'
}

function deploy_experiment_files {
  echo "Rsyncing experiment files..."
  rsync -avh --delete --exclude ".*" --exclude "metrics" --exclude "*.metrics" --info=progress2 ./ fledger:~/experiments/
}

function run_fleet_on_xdc {
  net_name="$1"
  fleet_id="$2"
  vm_amount="$3"
  bots_per_vm="$4"
  ssh -tt fledger "bash -c 'cd experiments && source /home/abehsser/.bash_profile && fleet $net_name $fleet_id $vm_amount $bots_per_vm'"
}

function main {
  check_usage

  echo "[deploying network $net_name]"
  deploy_network

  echo "Running bot on network [$net_name]"

  echo "[create fleet on hermes]"
  fleet_id=$(hermes_create_fleet)
  echo "FLEET_ID: $fleet_id"

  echo "[deploy experiment files]"
  deploy_experiment_files

  echo "[run fleet]"
  run_fleet_on_xdc "$net_name" "$fleet_id" "$vm_amount" "$bots_per_vm"
  bots_per_vm="$3"

  echo "Fleet deployed."
}

main "$@"
