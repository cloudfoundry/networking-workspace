#!/bin/bash

pipeline='cf-app-sd'
job='ushanka-smoke-tests'

while getopts 'p:j:' flag; do
  case "${flag}" in
    a) pipeline="${OPTARG}" ;;
    b) job="${OPTARG}" ;;
#    ?) echo $"Usage: $0 [-p pipeline] [-j job]"; exit 2 ;;
  esac
done

printf "Pipeline set to %s\n" "${pipeline}"
printf "Job set to %s\n" "${job}"

declare -a failed_jobs
declare -a failed_tests

hr() {
  local start=$'\e(0' end=$'\e(B' line='qqqqqqqqqqqqqqqq'
  local cols=${COLUMNS:-$(tput cols)}
  while ((${#line} < cols)); do line+="$line"; done
  printf '%s%s%s\n' "$start" "${line:0:cols}" "$end"
}

failed_tests=()
failed_jobs=( $(fly -t c2c builds -j $pipeline/$job -c 100 | grep failed | cut -f5 -d" ") )

printf "Failed job: https://c2c.ci.cf-app.com/teams/main/pipelines/${pipeline}/jobs/${job}/builds/%s\n" "${failed_jobs[@]}"
hr

for (( i=0; i<${#failed_jobs[@]}; i++ ));
do
printf "Fetching test failures for %s\n" "${failed_jobs[i]}"
failed_tests+=( $(fly -t c2c watch --job $pipeline/$job --build "${failed_jobs[i]}" | grep "\[Fail\]" -A 1 | grep build | cut -d"/" -f5-) )
done

hr

printf "%s\n" "${failed_tests[@]}" | sort | uniq -c | sort -k2nr 
