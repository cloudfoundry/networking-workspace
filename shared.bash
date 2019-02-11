#!/usr/bin/env bash

main() {
  setup_aliases() {
    alias vim=nvim
    alias vi=nvim
    alias ll="ls -al"
    alias be="bundle exec"
    alias bake="bundle exec rake"
    alias drm='docker rm $(docker ps -a -q)'
    alias drmi='docker rmi $(docker images -q)'
    alias bosh2=bosh

    #git aliases
    alias gst="git status"
    alias gd="git diff"
    alias gap="git add -p"
    alias gup="git pull -r"
    alias gp="git push"
    alias ga="git add"

    alias gbt="gobosh_target"
    alias gbtl="gobosh_target_lite"
    alias cft="cf_target"
    alias cftl="cf_target local"
    alias t="target"

    alias rg="ag"

    alias h?="history | grep"
    alias chg="credhub_get"
  }

  setup_environment() {
    export CLICOLOR=1
    export LSCOLORS exfxcxdxbxegedabagacad

    # go environment
    export GOPATH=$HOME/go

    # git duet config
    export GIT_DUET_GLOBAL=true
    export GIT_DUET_ROTATE_AUTHOR=1

    # setup path
    export PATH=$GOPATH/bin:$PATH:/usr/local/go/bin:$HOME/scripts:$HOME/workspace/routing-ci/scripts:/usr/ocal/opt/apr/bin:/usr/local/opt/apr-util/bin
    export EDITOR=nvim
  }

  setup_rbenv() {
    eval "$(rbenv init -)"
  }

  setup_aws() {
    # set awscli auto-completion
    complete -C aws_completer aws
  }

  setup_fasd() {
    local fasd_cache
    fasd_cache="$HOME/.fasd-init-bash"

    if [ "$(command -v fasd)" -nt "$fasd_cache" -o ! -s "$fasd_cache" ]; then
      fasd --init posix-alias bash-hook bash-ccomp bash-ccomp-install >| "$fasd_cache"
    fi

    source "$fasd_cache"
    eval "$(fasd --init auto)"
  }

  setup_completions() {
    [ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion
  }

  setup_direnv() {
    eval "$(direnv hook bash)"
  }

  setup_gitprompt() {
    if [ -f "$(brew --prefix)/opt/bash-git-prompt/share/gitprompt.sh" ]; then
      # git prompt config
      export GIT_PROMPT_SHOW_UNTRACKED_FILES=normal
      export GIT_PROMPT_ONLY_IN_REPO=0
      export GIT_PROMPT_THEME="Custom"

      source "$(brew --prefix)/opt/bash-git-prompt/share/gitprompt.sh"
    fi
  }

  setup_colors() {
    local colorscheme
    colorscheme="${HOME}/.config/colorschemes/scripts/base16-monokai.sh"
    [[ -s "${colorscheme}" ]] && source "${colorscheme}"
  }

  setup_ssh_agent() {
    if [[ ! -e ~/.ssh_agent ]]; then
      if [[ -n ${SSH_AUTH_SOCK} ]]; then
        ln -sf $SSH_AUTH_SOCK ~/.ssh_agent
      fi
    fi

    export SSH_AUTH_SOCK=~/.ssh_agent
  }

  setup_bosh_env_scripts() {
    local bosh_scripts
    bosh_scripts="${HOME}/workspace/routing-ci/scripts/script_helpers.sh"
    [[ -s "${bosh_scripts}" ]] && source "${bosh_scripts}"
  }

  setup_gpg_config() {
    local status
    status=$(gpg --card-status &> /dev/null; echo $?)

    if [[ "$status" == "0" ]]; then
      export SSH_AUTH_SOCK="${HOME}/.gnupg/S.gpg-agent.ssh"
    fi
  }

  local dependencies
    dependencies=(
        aliases
        environment
        colors
        rbenv
        aws
        fasd
        completions
        direnv
        gitprompt
        gpg_config
        bosh_env_scripts
        ssh_agent
      )

  for dependency in ${dependencies[@]}; do
    eval "setup_${dependency}"
    unset -f "setup_${dependency}"
  done
}

main
unset -f main

# FUNCTIONS

function reload() {
  source "${HOME}/.bash_profile"
}

reinstall() {
  local workspace
  workspace="~/workspace/networking-workspace"

  if [[ ! -d "${workspace}" ]]; then
    git clone https://github.com/cloudfoundry/networking-workspace "${workspace}"
  fi

  pushd "${workspace}" > /dev/null
    git diff --exit-code > /dev/null
    if [[ "$?" = "0" ]]; then
      git pull -r
      bash -c "./install.sh"
    else
      echo "Cannot reinstall. There are unstaged changes in the networking-workspace repo."
      git diff
    fi
  popd > /dev/null
}

cf_seed() {
  cf create-org o
  cf create-space -o o s
  cf target -o o -s s
}

cf_clean() {
  : "${1?"Please provide a target to delete. For example: cf_clean \"CATS|SMOKE|SCALING\""}"
  cf buildpacks | grep -E "${1}" | awk '{ print $1 }' | xargs -n 1 -P 8 cf delete-buildpack -f
  cf orgs | grep -E "${1}" | grep -v persistent | xargs -n 1 -P 8 cf delete-org -f
  cf quotas | grep -E "${1}" | grep -v persistent | awk '{ print $1 }' | xargs -n 1 -P 8 cf delete-quota -f
}

gimme_certs() {
	local common_name
	common_name="${1:-fake}"
	local ca_common_name
	ca_common_name="${2:-${common_name}_ca}"
	local depot_path
	depot_path="${3:-fake_cert_stuff}"
	certstrap --depot-path ${depot_path} init --passphrase '' --common-name "${ca_common_name}"
	certstrap --depot-path ${depot_path} request-cert --passphrase '' --common-name "${common_name}"
	certstrap --depot-path ${depot_path} sign --passphrase '' --CA "${ca_common_name}" "${common_name}"
}

bbl_gcp_creds () {
  lpass show "BBL GCP Creds" --notes
}

eval_bbl_gcp_creds() {
  eval "$(bbl_gcp_creds)"
}

pullify() {
  git config --add remote.origin.fetch '+refs/pull/*/head:refs/remotes/origin/pr/*'
  git fetch origin
}

istio_docker() {
  local istio_dir
  istio_dir="${1}"

  if [[ -z "${istio_dir}" ]]; then
    echo "WARNING: istio_dir not set"
    echo "Setting istio directory to ~/workspace/istio-release/src/istio.io/istio"
    echo "You may optionally pass your preferred istio directory as the first argument 😀 "
    istio_dir="${HOME}/workspace/istio-release/src/istio.io/istio"
  else
    echo "istio_directory set to ${istio_dir}"
  fi

  echo "Getting istio/ci tags..."
  local tag
  tag=$(curl -s "https://hub.docker.com/v2/repositories/istio/ci/tags/" | jq -r '.results|.[0].name')

  echo "Getting most recent istio/ci images..."
  docker pull istio/ci:"${tag}"

  local image_id
  image_id=$(docker images -f reference=istio/ci --format "{{.ID}}" | head -n1)

  docker run -u root -it --cap-add=NET_ADMIN -v "${istio_dir}":/go/src/istio.io/istio "${image_id}" /bin/bash
}

default_hours() {
  local current_hour=$(date +%H | sed 's/^0//')
  local result=$((17 - current_hour))
  if [[ ${result} -lt 1 ]]; then
    result=1
  fi
  echo -n ${result}
}

set_key() {
  local hours=$1

  /usr/bin/ssh-add -D

  echo "Setting hours to: $hours"
  lpass show --notes 'ProductivityTools/id_rsa' | /usr/bin/ssh-add -t ${hours}H -
}

set-git-keys() {
  local email=$1
  local hours=$2

  if [[ -z ${email} ]]; then
    echo "Usage: $0 [LastPass email or git author initials] [HOURS (optional)]"
    return
  fi

  if git_author_path "/authors/$email" >/dev/null 2>&1; then
    echo "Adding key for $(bosh int ${HOME}/.git-authors --path="/authors/$email" | sed 's/;.*//')"
    email="$(bosh int ${HOME}/.git-authors --path="/authors/$email" | sed 's/;.*//')@$(bosh int ${HOME}/.git-authors --path="/email/domain")"
  fi

  if [[ -z ${hours} ]]; then
    hours=$(default_hours)
  fi

  if ! [[ $(lpass status) =~ $email ]]; then
    lpass login "$email"
  fi
  set_key ${hours}
}

function current_branch() { # Gets current branch
  git rev-parse --abbrev-ref HEAD
}

function parse_branch() { # Gets current branch with parens around it for some legacy things
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

function gh_remote_path() { # Parses the 'remote path' of the repo: username/repo
  REMOTE=${1:-origin}

  GH_PATH=`git remote -v | tr ':' ' ' | tr '.' ' ' | grep $REMOTE | awk '/push/ {print $4}'`
  echo ${GH_PATH#com/}
}

function gh() { # Opens current branch on Github, works for all repos
  REMOTE=${1:-origin}

  echo 'Opening branch on Github...'
  open "https://github.com/$(gh_remote_path $REMOTE)/tree/$(current_branch)"
}

function newpr() { # Opens current branch on Github in the "Open a pull request" compare view
  echo 'Opening compare on Github...'
  open "https://github.com/$(gh_remote_path)/compare/$(current_branch)?expand=1"
}

function gpu() { # Push upstream
  git push --set-upstream origin `current_branch`
}

function mkd() { # Create a new directory and enter it
  mkdir -p "$@" && cd "$_";
}

function loop() { # Repeats a given command forever
  local i=2 t=1 cond

  [ -z ${1//[0-9]/} ] && i=$1 && shift
  [ -z ${1//[0-9]/} ] && t=$1 && shift && cond=1
  while [ $t -gt 0 ]; do
    sleep $i
    [ $cond ] && : $[--t]
    $@
  done
}

function server() { # Create webserver from current directory
  local port="${1:-8000}";
  sleep 1 && open "http://localhost:${port}/" &
  # Set the default Content-Type to `text/plain` instead of `application/octet-stream`
  # And serve everything as UTF-8 (although not technically correct, this doesn’t break anything for binary files)
  python -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port";
}

function nuke() { # Straight up murders all processes matching first arg
  ps ax | grep $1 | awk '{print $1}' | xargs kill -9
}

function politely_nuke() { # As above but nicely
  ps ax | grep $1 | awk '{print $1}' | xargs kill
}

function smart_bomb() { # Don't use this
  killall -15 $1 2> /dev/null || killall -2 $1 2> /dev/null || killall -1 $1 2> /dev/null || killall -9 $1 2> /dev/null
}

function clear_port() { # Finds whatever is using a given port (except chrome) and kills it
  lsof -t -i tcp:$1 | ag -v "$(ps aux|ag Chrome|tr -s ' '|cut -d ' ' -f 2|fmt -1024|tr ' ' '|')"| xargs kill -9
}

function v() { # Use fasd to open a file in vim from anywhere
  nvim `f "$1" | awk "{print $2}"`
}

function credhub_get() {
  credhub get -n `credhub find -n "$1" | grep "name" | head -n 1 | sed 's/- name: //'`
}

function toolsmiths() {
  echo "Opening https://environments.toolsmiths.cf-app.com..."
  open https://environments.toolsmiths.cf-app.com
  echo "NOTE: Run create_service_account_key_for_toolsmiths_env <story_id>"
  echo "      to create a service account with a key for toolsmiths env."
}


# NEEDS CONSOLIDATION WITH ROUTING SCRIPTS

bosh_ssh_c2c() {
  if (( $# != 1 ))
    then echo "Usage: bosh_ssh_c2c <env>"
  else
    bosh target bosh.$1.c2c.cf-app.com
    bosh download manifest $1-diego /tmp/$1-diego.yml
    bosh -d /tmp/$1-diego.yml ssh --gateway_host bosh.$1.c2c.cf-app.com --gateway_user vcap --gateway_identity_file ~/workspace/cf-networking-deployments/environments/$1/keypair/id_rsa_bosh
  fi
}

cf_target() {
  if [ $# = 0 ]; then
    echo "missing environment-name"
    echo ""
    echo "example usage:"
    echo "cft environment-name"
    return
  fi
  env=$1
  workspace=$2

  if [ "$env" = "ci" ]; then
    echo "no CF deployed in ci env."
    return
  fi

  if [ "$env" = "local" ] || [ "$env" = "lite" ]; then
    password=$(grep cf_admin_password "${HOME}/workspace/cf-networking-deployments/environments/${env}/deployment-vars.yml" | cut -d" " -f2)
  else
    password=$(credhub get -n "/bosh-${env}/cf/cf_admin_password" | bosh int --path /value -)
  fi

  if [ "$workspace" = "routing" ]; then
    system_domain="${env}.routing.cf-app.com"
  elif [ "$env" = "local" ] || [ "$env" = "lite" ]; then
    system_domain="bosh-lite.com"
  else
    system_domain="${env}.c2c.cf-app.com"
  fi

  cf api "api.${system_domain}" --skip-ssl-validation
  cf auth admin "${password}"
}

gobosh_target() {
  gobosh_untarget
  if [ $# = 0 ]; then
    return
  fi
  export BOSH_ENV=$1
  if [ "$BOSH_ENV" = "local" ] || [ "$BOSH_ENV" = "lite" ]; then
    gobosh_target_lite
    return
  fi

  if [[ "${BOSH_ENV}" == "ci" ]]; then
    pushd $(mktemp -d) > /dev/null
      gsutil cp gs://c2c-bbl-states/ci ci.tgz
      tar xf ci.tgz
      eval "$(bbl print-env)"
    popd > /dev/null
    export BOSH_DEPLOYMENT="concourse"
    return
  fi

  workspace=$2
  if [ "$workspace" = "pcf" ]; then
    export BOSH_DIR=~/workspace/pcf-networking-deployments/environments/$BOSH_ENV
  elif [ "$workspace" = "routing" ]; then
    export BOSH_DIR=~/workspace/deployments-routing/$BOSH_ENV/bbl-state
  else
    export BOSH_DIR=~/workspace/cf-networking-deployments/environments/$BOSH_ENV
  fi

  pushd $BOSH_DIR 1>/dev/null
      eval "$(bbl print-env)"
  popd 1>/dev/null

  export BOSH_DEPLOYMENT="cf"
}

gobosh_untarget() {
  unset BOSH_ENV
  unset BOSH_DIR
  unset BOSH_USER
  unset BOSH_PASSWORD
  unset BOSH_ENVIRONMENT
  unset BOSH_GW_HOST
  unset BOSH_GW_PRIVATE_KEY
  unset BOSH_CA_CERT
  unset BOSH_DEPLOYMENT
  unset BOSH_CLIENT
  unset BOSH_CLIENT_SECRET
}

target() {
  gobosh_target ${@}
  cf_target ${@}
}

gobosh_target_lite() {
  gobosh_untarget
  export BOSH_DIR=~/workspace/cf-networking-deployments/environments/local

  pushd $BOSH_DIR >/dev/null
    export BOSH_CLIENT="admin"
    export BOSH_CLIENT_SECRET="$(bosh int ./creds.yml --path /admin_password)"
    export BOSH_ENVIRONMENT="vbox"
    export BOSH_CA_CERT=/tmp/bosh-lite-ca-cert
    bosh int ./creds.yml --path /director_ssl/ca > $BOSH_CA_CERT
  popd 1>/dev/null
  unset BOSH_ALL_PROXY

  export BOSH_DEPLOYMENT=cf;
  if [ "$env" = "ci" ]; then
    export BOSH_DEPLOYMENT=concourse
  fi
}

readd_local_route() {
  ips="10.244.0.0/16"
  gw="192.168.50.6"
  sudo route delete -net "$ips" "$gw"
  sudo route add -net "$ips" "$gw"
}

ssh_bosh_lite_director() {
  local creds=~/workspace/cf-networking-deployments/environments/local/creds.yml
  bosh int $creds --path /jumpbox_ssh/private_key > /tmp/jumpbox.key
  chmod 600 /tmp/jumpbox.key
  ssh jumpbox@192.168.50.6 -i /tmp/jumpbox.key
}

gobosh_build_manifest() {
  bosh -d cf build-manifest -l=$BOSH_DIR/deployment-env-vars.yml --var-errs ~/workspace/cf-deployment/cf-deployment.yml
}

gobosh_patch_manifest() {
  pushd ~/workspace/cf-deployment 1>/dev/null
    git apply ../cf-networking-ci/netman-cf-deployment.patch
  popd 1>/dev/null
}

extract_manifest() {
  bosh task $1 --debug | deployment-extractor
}

create_upload() {
  bosh create-release --force --timestamp-version && bosh upload-release
}

upload_bosh_stemcell() {
  STEMCELL_VERSION="$(bosh int ~/workspace/cf-deployment/cf-deployment.yml --path=/stemcells/0/version)"
  echo "will upload stemcell ${STEMCELL_VERSION}"
  bosh -e vbox upload-stemcell "https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent?v=${STEMCELL_VERSION}"
}

deploy_bosh_lite() {
  bosh deploy --no-redact -n ~/workspace/cf-deployment/cf-deployment.yml \
  -o ~/workspace/cf-deployment/operations/bosh-lite.yml \
  -o ~/workspace/cf-networking-deployments/environments/local/instance-count-overrides.yml \
  -o ~/workspace/cf-deployment/operations/enable-service-discovery.yml \
  -o ~/workspace/cf-networking-release/manifest-generation/opsfiles/use-latest.yml \
  -o ~/workspace/silk-release/opsfiles/use-latest.yml \
  -o $BOSH_DIR/opsfile.yml \
  --vars-store ~/workspace/cf-networking-deployments/environments/local/deployment-vars.yml \
  -v system_domain=bosh-lite.com
}

gobosh_deploy() {
  bosh deploy -n ~/workspace/cf-deployment/cf-deployment.yml \
  -o ~/workspace/cf-deployment/operations/use-compiled-releases.yml \
  -o ~/workspace/cf-networking-release/manifest-generation/opsfiles/cf-networking.yml \
  -o ~/workspace/cf-networking-release/manifest-generation/opsfiles/use-latest.yml \
  -o $BOSH_DIR/opsfile.yml \
  --vars-store $BOSH_DIR/vars-store.yml \
  -v system_domain=$(echo "${BOSH_DIR}" | cut -f 7 -d '/').c2c.cf-app.com
}

create_c2c_bosh_lite() {
    gobosh_target_lite;
    bosh create-env ~/workspace/bosh-deployment/bosh.yml \
    --state ~/workspace/cf-networking-deployments/environments/local/state.json \
    -o ~/workspace/bosh-deployment/virtualbox/cpi.yml \
    -o ~/workspace/bosh-deployment/virtualbox/outbound-network.yml \
    -o ~/workspace/bosh-deployment/bosh-lite.yml \
    -o ~/workspace/bosh-deployment/bosh-lite-runc.yml \
    -o ~/workspace/bosh-deployment/jumpbox-user.yml \
    -o ~/workspace/bosh-deployment/local-dns.yml \
    --vars-store ~/workspace/cf-networking-deployments/environments/local/creds.yml \
    -v director_name="Bosh Lite Director" \
    -v internal_ip=192.168.50.6 \
    -v internal_gw=192.168.50.1 \
    -v internal_cidr=192.168.50.0/24 \
    -v outbound_network_name="NatNetwork"

    bosh -e 192.168.50.6 --ca-cert <(bosh int ~/workspace/cf-networking-deployments/environments/local/creds.yml --path /director_ssl/ca) alias-env vbox
    export BOSH_CLIENT="admin"
    export BOSH_CLIENT_SECRET="$(bosh int ~/workspace/cf-networking-deployments/environments/local/creds.yml --path /admin_password)"
    export BOSH_ENVIRONMENT="vbox"
    export BOSH_DEPLOYMENT="cf"
    export BOSH_CA_CERT="/tmp/bosh-lite-ca-cert"
    bosh int ~/workspace/cf-networking-deployments/environments/local/creds.yml --path /director_ssl/ca > ${BOSH_CA_CERT}

    STEMCELL_VERSION="$(bosh int ~/workspace/cf-deployment/cf-deployment.yml --path=/stemcells/0/version)"
    echo "will upload stemcell ${STEMCELL_VERSION}"
    bosh -e vbox upload-stemcell "https://bosh.io/d/stemcells/bosh-warden-boshlite-ubuntu-trusty-go_agent?v=${STEMCELL_VERSION}"

    bosh -e vbox -n update-cloud-config ~/workspace/cf-deployment/iaas-support/bosh-lite/cloud-config.yml
}

delete_c2c_bosh_lite() {
    bosh delete-env ~/workspace/bosh-deployment/bosh.yml \
    --state ~/workspace/cf-networking-deployments/environments/local/state.json \
    -o ~/workspace/bosh-deployment/virtualbox/cpi.yml \
    -o ~/workspace/bosh-deployment/virtualbox/outbound-network.yml \
    -o ~/workspace/bosh-deployment/bosh-lite.yml \
    -o ~/workspace/bosh-deployment/bosh-lite-runc.yml \
    -o ~/workspace/bosh-deployment/jumpbox-user.yml \
    --vars-store ~/workspace/cf-networking-deployments/environments/local/creds.yml \
    -v director_name="Bosh Lite Director" \
    -v internal_ip=192.168.50.6 \
    -v internal_gw=192.168.50.1 \
    -v internal_cidr=192.168.50.0/24 \
    -v outbound_network_name="NatNetwork"
}

unbork_consul() {
  bosh vms | grep consul | cut -d ' ' -f1 > /tmp/consul-vms
  cat /tmp/consul-vms | xargs -n1 bosh ssh -c "sudo /var/vcap/bosh/bin/monit stop consul_agent"
  cat /tmp/consul-vms | xargs -n1 bosh ssh -c "sudo rm -rf /var/vcap/store/consul_agent/*"
  cat /tmp/consul-vms | xargs -n1 bosh ssh -c "sudo /var/vcap/bosh/bin/monit start consul_agent"
}


function windows_port_forward() {
  echo "Port forwarding from $1"
  ssh -f -L 3389:$1:3389 -N -i ${BOSH_GW_PRIVATE_KEY} ${BOSH_GW_USER}@${BOSH_GW_HOST}
}

function story() {
  if [ -n "$TRACKER_API_TOKEN" ]; then
    STORY_TITLE=" $(curl -s -H "X-TrackerToken: $TRACKER_API_TOKEN" \
      "https://www.pivotaltracker.com/services/v5/projects/$TRACKER_PROJECT/stories/${1/\#/}" \
      | jq -r .name)"
  else
    STORY_TITLE=''
  fi
  printf "\n\n[$1]$STORY_TITLE" > ~/.git-tracker-story
}

function create_service_account_key_for_toolsmiths_env() {
  if [[ $# != 1 ]]; then
    echo "Usage: create_service_account_key_for_toolsmiths_env <story_id>"
    return 1
  fi

  local story_id="${1}"
  local service_account_name="opsman-${story_id}"
  local gcp_project_name="$(gcloud config get-value project)"
  local service_account_email="${service_account_name}@${gcp_project_name}.iam.gserviceaccount.com"
  local key_file_name="$(mktemp)"

  gcloud iam service-accounts create "${service_account_name}" \
    --display-name "${service_account_name}" 1> /dev/null
  gcloud projects add-iam-policy-binding "${gcp_project_name}" \
    --member "serviceAccount:${service_account_email}" \
    --role roles/editor 1> /dev/null
  gcloud iam service-accounts keys create "${key_file_name}" \
    --iam-account "${service_account_email}" 1> /dev/null

  echo "NOTE: Remember to clean up your key after your done using remove_service_account_key_for_toolsmiths_env." 1>&2

  cat "${key_file_name}"
  rm "${key_file_name}"
}

function remove_service_account_key_for_toolsmiths_env() {
  if [[ $# != 1 ]]; then
    echo "Usage: remove_service_account_key_for_toolsmiths_env <story_id>"
    return 1
  fi

  local story_id="${1}"
  local service_account_email="opsman-${story_id}@cf-container-networking-gcp.iam.gserviceaccount.com"

  gcloud iam service-accounts delete "${service_account_email}"
}
