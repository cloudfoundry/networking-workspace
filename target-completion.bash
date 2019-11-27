#!/usr/bin/env bash

_target_completion()
{
  if [ "${#COMP_WORDS[@]}" != "2" ]; then
    return
  fi

  local lookup_dirs=(
    "${HOME}/workspace/deployments-routing"
    "${HOME}/workspace/networking-oss-deployments/environments"
    "${HOME}/workspace/cf-networking-deployments/environments"
  )

  local envs="$(find "${lookup_dirs[@]}" -not -path '*/\.*' -type d -maxdepth 1 -print0 | xargs -0 -n 1 basename | uniq | sort)"

  local cur=${COMP_WORDS[COMP_CWORD]}

  COMPREPLY=($(compgen -W "${envs}" -- $cur))
}

complete -o nospace -F _target_completion t target gbt gobosh_target cf-target

_gke_target_completion() {
  if [ "${#COMP_WORDS[@]}" != "2" ]; then
    return
  fi

  local clusters="$(gcloud container clusters list 2>/dev/null | grep RUNNING | awk '{print $1}')"

  local cur=${COMP_WORDS[COMP_CWORD]}

  COMPREPLY=($(compgen -W "${clusters}" -- $cur))
}

complete -o nospace -F _gke_target_completion gke_target
