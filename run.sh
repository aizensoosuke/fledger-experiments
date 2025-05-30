#!/bin/bash

# CHANGE THESE
project="fledger"
username="abehsser"

INFLUX_HOST="https://influxdb.abehssera.com"
INFLUX_ORG="fledger"
INFLUX_TOKEN="i9eFePFcoFKLjGNlYgY090_CULrCPEmNE_8ZlY8rLL7MUNywcBJVTKNe9B8Cv-H5DzUHTTz_tMi1VoAuBzkSQA=="
INFLUX_BUCKET="fledger-demo"
# END CHANGE THESE

exp="$1"
net=$(grep -e "NETWORK=" "$exp/env" | sed -e 's/NETWORK=//')
realization="$net.$project.$username"

echo "Running experiment [$exp] on network [$net]"
echo

currentnet=$(cat attached-net)

if test -z "$currentnet" || test "$currentnet" != "$net"; then
  echo "INFO: Network [$net] is not deployed or attached. Deploying and/or attaching..."
  echo "    Checking if $realization exists..."
  mrg show realization "$realization"

  if test $? -eq 0; then
    echo "    Realization exists, attaching..."
    mrg xdc detach fledger.abehsser >/dev/null || exit 1
    mrg xdc attach fledger.abehsser "$realization" >/dev/null || {
      echo "FATAL: could not attach realization"
      exit 1
    }
  else
    echo "    Realization not found, deploying network..."
    read -r -p "    Deploy network $net (y/n)? " choice
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

    ./deploy-network.sh "./networks/$net" || exit 1
  fi
  echo "INFO: Network deployed and attached."
  echo "$net" >./attached-net
else
  echo "INFO: Network [$net] is already attached."
  echo "   NOTE: If the network is not actually attached, please empty the file \`attached-net\`"
fi

echo "[deploy experiment files]"
make

echo "[run experiment]"
ssh -tt fledger "bash -c 'cd experiments && source /home/abehsser/.bash_profile && exp $exp'"

echo "[download metrics]"
echo "compress..."
ssh fledger "bash -c 'cd ~/experiments && rm -f metrics.tar.gz && tar -czf metrics.tar.gz assembled.metrics'"

echo "download..."
mkdir -p "metrics/$exp"
scp fledger:experiments/metrics.tar.gz .

echo "uncompress..."
tar -xf metrics.tar.gz

mv assembled.metrics latest.metrics
filename=metrics/$exp/$(date -d "today" +"%Y-%m-%d-%H%M%S").metrics
cp latest.metrics "$filename"
echo "...archived to $filename"

echo "[upload metrics to influxdb]"
influx write --host "$INFLUX_HOST" --org "$INFLUX_ORG" --token "$INFLUX_TOKEN" --bucket "$INFLUX_BUCKET" --file latest.metrics --debug
