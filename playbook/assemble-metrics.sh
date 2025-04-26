#!/bin/bash

instances=$(ls ~/env.systemd)

if test -z "$instances"; then
  echo "WARNING: no instances!"
  exit
fi

echo "[gather metrics]"
touch ~/metrics

for instance in $instances; do
  service="$instance.service"

done

# - name: Find fledger services
#   ansible.builtin.find:
#     paths: ~/env.systemd
#   register: fledger_services
#
# - name: Download metrics
#   ansible.builtin.fetch:
#     src: "/tmp/{{ item.path | basename }}.metrics"
#     flat: true
#     dest: "metrics/"
#   loop: "{{ fledger_services | dict2items }}"
