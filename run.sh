#!/bin/bash

set -euo pipefail

function get_env {
  name="$1"
  env_file="./env"
  if test -n "$2"; then
    env_file="$2"
  fi
  value=$(grep -e "$name=" "$env_file" | sed -e "s/$name=//")
  echo "$value"
}

function set_env {
  name="$1"
  value="$2"
  env_file="./env"
  if test -n "$3"; then
    env_file="$3"
  fi
  sed -i -e "s/^$name=.*$/$name=$value/" "$env_file"
}

exp_dir="$1"
env_file="$exp_dir/env"
net_name=$(get_env NETWORK "$env_file")
filler_amount=$(get_env FILLER_AMOUNT "$exp_dir/configure.sh")
hermes_url=$(get_env HERMES_URL)
hermes_token=$(get_env HERMES_TOKEN)

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
function hermes_create_experiment {
  experiment_id=$(
    hermes_post \
      "$hermes_url/api/experiments" \
      "name=$exp_dir&pages_amount=$filler_amount" |
      jq -r '.id'
  )
  set_env EXPERIMENT_ID "$experiment_id" "$env_file"
}

function deploy_experiment_files {
  echo "Rsyncing experiment files..."
  rsync -avh --delete --exclude ".*" --exclude "metrics" --exclude "*.metrics" --info=progress2 ./ fledger:~/experiments/
}

function run_experiment_on_xdc {
  ssh -tt fledger "bash -c 'cd experiments && source /home/abehsser/.bash_profile && exp $exp_dir'"
}

function hermes_end_experiment {
  experiment_id=$(get_env EXPERIMENT_ID "$env_file")
  hermes_get "$hermes_url/api/experiments/${experiment_id}/end"
}

function main {
  echo "[deploying network $net_name]"
  deploy_network

  echo "Running experiment [$exp_dir] on network [$net_name]"

  echo "[create experiment on hermes]"
  hermes_create_experiment

  echo "[deploy experiment files]"
  deploy_experiment_files

  echo "[run experiment]"
  run_experiment_on_xdc

  echo "[end experiment on hermes]"
  hermes_end_experiment
}

main
