#!/bin/bash

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "incorrect paramaters. usage: $0 pas-version release"
  exit 1
fi

pas_version=$1
release=$2

kiln_file=~/workspace/p-runtime/Kilnfile.lock
(
  cd ~/workspace/p-runtime 
  git co rel/${pas_version} 2> /dev/null 1> /dev/null
  cat ${kiln_file} | grep "${release}" -A 2 | grep version | awk '{print $2}'
  git co - 2> /dev/null 1> /dev/null
)

