#!/bin/bash

# CHANGE THESE
INFLUX_HOST="https://influxdb.abehssera.com"
INFLUX_ORG="fledger"
INFLUX_TOKEN="F7y_RJHnXA0szQHDhEiuRDAw7B2etGywSc-wdMK-BJtkXwplqXe5ogCcXDEJJR18ZvWJ87kwxckl6n1lFu9B-Q=="
INFLUX_BUCKET="fledger"
# END CHANGE THESE

if test "$#" -ne 1; then
  echo "usage: $0 delete|write"
  exit 1
fi

cmd="$1"

if test "$cmd" = "delete"; then
  echo "[delete old metrics from influxdb]"
  influx delete --org "$INFLUX_ORG" --bucket "$INFLUX_BUCKET" --token "$INFLUX_TOKEN" --host "$INFLUX_HOST" --start 2025-01-01T00:00:00Z --stop "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" --http-debug
elif test "$cmd" = "write"; then
  echo "[upload metrics to influxdb]"
  influx write --host "$INFLUX_HOST" --org "$INFLUX_ORG" --token "$INFLUX_TOKEN" --bucket "$INFLUX_BUCKET" --file latest.metrics --debug
else
  echo "usage: $0 delete|write"
  exit 1
fi
