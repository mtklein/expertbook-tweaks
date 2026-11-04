#!/bin/bash
# Loads all CPUs in Performance for 50s, printing package power, temperature and PL1 every 5s.
# Usage: pkexec bash tools/power-trace.sh
E=/sys/class/powercap/intel-rapl:0/energy_uj; T=$(for z in /sys/class/thermal/thermal_zone*; do [ "$(cat $z/type)" = x86_pkg_temp ] && echo $z/temp; done)
powerprofilesctl set performance; sleep 6
pids=(); for i in $(seq $(nproc)); do ( while :; do :; done ) & pids+=($!); done
prev=$(cat $E)
for s in $(seq 5 5 50); do
  sleep 5; now=$(cat $E)
  printf '%3ss  %5.1f W  %3d C  PL1=%sW\n' $s $(awk -v d=$((now-prev)) 'BEGIN{print d/5e6}') $(( $(cat $T)/1000 )) $(( $(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw)/1000000 ))
  prev=$now
done
kill "${pids[@]}"; wait 2>/dev/null
powerprofilesctl set balanced
