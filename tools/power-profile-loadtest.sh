#!/bin/bash
# Usage: pkexec bash tools/power-profile-loadtest.sh   (on AC and on battery to compare)
# Run as root. Loads all CPUs for 60s in each power profile and reports package power.
E=/sys/class/powercap/intel-rapl:0/energy_uj
MAX=$(cat /sys/class/powercap/intel-rapl:0/max_energy_range_uj)
N=$(nproc)

energy() { cat $E; }
watts() {  # watts <start_uj> <end_uj> <seconds>
  local d=$(( $2 - $1 )); (( d < 0 )) && d=$(( d + MAX ))
  awk -v d=$d -v s=$3 'BEGIN { printf "%.1f", d / 1e6 / s }'
}
mhz() { awk '{ s += $1; n++ } END { printf "%.0f", s / n / 1000 }' /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; }

for p in power-saver balanced performance; do
  powerprofilesctl set $p
  sleep 8
  pids=()
  for i in $(seq $N); do ( while :; do :; done ) & pids+=($!); done
  e0=$(energy); sleep 10; e1=$(energy); f1=$(mhz)
  sleep 20; e2=$(energy); sleep 30; e3=$(energy); f3=$(mhz)
  kill "${pids[@]}" 2>/dev/null; wait 2>/dev/null
  printf '%-12s first 10s: %5s W   last 30s: %5s W   avg clock %s -> %s MHz\n' \
    "$p" "$(watts $e0 $e1 10)" "$(watts $e2 $e3 30)" "$f1" "$f3"
  sleep 10
done
powerprofilesctl set balanced
