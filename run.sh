#!/bin/bash

# CHANGE THESE
SPHERE_PROJECT="fledger"
SPHERE_USERNAME="abehsser"
# END CHANGE THESE

EXP="$1"
NET=$(grep -e "NETWORK=" "$EXP/env" | sed -e 's/NETWORK=//')
REALIZATION="$NET.$SPHERE_PROJECT.$SPHERE_USERNAME"

echo "Running experiment [$EXP] on network [$NET]"
echo

currentnet=$(cat attached-net)

if test -z "$currentnet" || test "$currentnet" != "$NET"; then
  echo "INFO: Network [$NET] is not deployed or attached. Deploying and/or attaching..."
  echo "    Checking if $REALIZATION exists..."
  mrg show realization "$REALIZATION"

  if test $? -eq 0; then
    echo "    Realization exists, attaching..."
    mrg xdc detach fledger.abehsser >/dev/null || exit 1
    mrg xdc attach fledger.abehsser "$REALIZATION" >/dev/null || {
      echo "FATAL: could not attach realization"
      exit 1
    }
  else
    echo "    Realization not found, deploying network..."
    read -r -p "    Deploy network $NET (y/n)? " choice
    case "$choice" in
    y | Y) echo "yes" ;;
    n | N)
      echo "no"
      exit 0
      ;;
    *)
      echo "invalid"
      exit 1
      ;;
    esac

    ./deploy-network.sh "./networks/$NET" || exit 1
  fi
  echo "INFO: Network deployed and attached."
  echo "$NET" >./attached-net
else
  echo "INFO: Network [$NET] is already attached."
  echo "   NOTE: If the network is not actually attached, please empty the file \`attached-net\`"
fi

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
