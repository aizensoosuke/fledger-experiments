#!/bin/bash

set -euo pipefail

EXP="$1"
NET=$(grep -e "NETWORK=" "$EXP/env" | sed -e 's/NETWORK=//')

echo "Running experiment [$EXP] on network [$NET]"
echo

echo [deploy network]
./deploy-network.sh "networks/$NET"

echo "[create experiment for dashboard]"
FILLER_AMOUNT=$(grep -e "FILLER_AMOUNT=" "$EXP/configure.sh" | sed -e 's/FILLER_AMOUNT=//')
EXPERIMENT_ID=$(
  curl -X POST https://fledger.yohan.ch/api/experiments/ \
    -H 'Authorization: Bearer 1|d4EeHkRPlqwpgLpALyTor5FxHI4NWg1LXJtf5NZBfd82aa17' \
    -H 'Accept: application/json' \
    -d "name=$EXP&pages_amount=$FILLER_AMOUNT" |
    jq -r '.id'
)

sed -i -e "s/^EXPERIMENT_ID=.*$/EXPERIMENT_ID=${EXPERIMENT_ID}/" "$EXP/env"

echo "[deploy experiment files]"
make

echo "[run experiment]"
ssh -tt fledger "bash -c 'cd experiments && source /home/abehsser/.bash_profile && exp $EXP'"

echo "[end]"
curl "https://fledger.yohan.ch/api/experiments/${EXPERIMENT_ID}/end" \
  -H 'Authorization: Bearer 1|d4EeHkRPlqwpgLpALyTor5FxHI4NWg1LXJtf5NZBfd82aa17' \
  -H 'Accept: application/json'
