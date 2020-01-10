#!/bin/bash

# Exit when a command exits with a non-zero code
# Also exit when there are unset variables
set -eu

main() {
  echo "Welcome to THE NETWORKING PROGRAM 🎉🎉🎉"
  cd ~/workspace/networking-workspace

  echo "Enable passwordless sudo..."
   sudo grep 'pivotal' /etc/sudoers || echo $(echo "pivotal ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers)

  echo "Add daily workstation installation to launchd..."
  cp ~/workspace/networking-workspace/workstation.install.daily.plist ~/Library/LaunchAgents/workstation.install.daily.plist
  launchctl load ~/Library/LaunchAgents/workstation.install.daily.plist

  echo "Enable key repeat"
  defaults write -g ApplePressAndHoldEnabled -bool false

  # adding the path so it can run in bg
  export GOPATH=~/go
  export PATH=$GOPATH/bin:$PATH:/usr/local/go/bin:$HOME/scripts:$HOME/workspace/deployments-routing/scripts:/usr/ocal/opt/apr/bin:/usr/local/opt/apr-util/bin:/usr/local/sbin:/usr/local/bin

  git update-index --assume-unchanged custom-commands.sh

  cd $(dirname $0)

  brew_all_the_things
  setup_git
  setup_ssh
  install_gpg
  install_ruby
  install_sshb0t
  install_vimfiles

  echo "Symlinking scripts into ~/scripts"
  ln -sfn $PWD/scripts ${HOME}/scripts

  echo "Creating workspace..."
  workspace=${HOME}/workspace
  mkdir -p $workspace

  echo "Creating go/src..."
  go_src=${HOME}/go/src
  if [ ! -e ${go_src} ]; then
    mkdir -pv ${HOME}/go/src
  fi

  if [ -L ${go_src} ]; then
    echo "${go_src} exists, but is a symbolic link"
  fi

  echo "Installing bosh-target..."
  GOPATH="${HOME}/go" go get -u github.com/cf-container-networking/bosh-target

  echo "Installing cf-target..."
  GOPATH="${HOME}/go" go get -u github.com/dbellotti/cf-target

  echo "Installing hclfmt..."
  GOPATH="${HOME}/go" go get -u github.com/fatih/hclfmt

  echo "Installing ginkgo..."
  GOPATH="${HOME}/go" go get -u github.com/onsi/ginkgo/ginkgo

  echo "Installing gomega..."
  GOPATH="${HOME}/go" go get -u github.com/onsi/gomega

  echo "Installing counterfeiter..."
  GOPATH="${HOME}/go" go get -u github.com/maxbrunsfeld/counterfeiter

  echo "Install deployment extractor..."
  GOPATH="${HOME}/go" go get -u github.com/kkallday/deployment-extractor

  echo "Install go-langserver for luan/nvim config (until gopls is ready)..."
  GOPATH="${HOME}/go" go get -u github.com/sourcegraph/go-langserver

  echo "Installing fly..."
  set +e
  if [ -z "$(fly -v)" ]; then
    wget https://github.com/concourse/concourse/releases/download/v4.2.1/fly_darwin_amd64
    mv fly_darwin_amd64 /usr/local/bin/fly
    chmod +x /usr/local/bin/fly
  fi
  set -e

  if [ ! -f ~/.flyrc ]; then
    cp flyrc ~/.flyrc
  else
    echo ".flyrc file present, not overwriting"
  fi

  echo "Configuring Spectacle..."
  cp -f "$(pwd)/com.divisiblebyzero.Spectacle.plist" "${HOME}/Library/Preferences/"

  echo "Setting keyboard repeat rates..."
  defaults write -g InitialKeyRepeat -int 25 # normal minimum is 15 (225 ms)
  defaults write -g KeyRepeat -int 2 # normal minimum is 2 (30 ms)

  GOPATH="${HOME}/go" all_the_repos

  echo "Downloading additional command line completion scripts"
  ln -sf /Applications/Docker.app/Contents/Resources/etc/docker.bash-completion $(brew --prefix)/etc/bash_completion.d/docker
  ln -sf /Applications/Docker.app/Contents/Resources/etc/docker-machine.bash-completion $(brew --prefix)/etc/bash_completion.d/docker-machine
  ln -sf /Applications/Docker.app/Contents/Resources/etc/docker-compose.bash-completion $(brew --prefix)/etc/bash_completion.d/docker-compose

  echo "Configuring databases..."
  ./scripts/setup_routing_dbs

  install_tmuxfiles

  echo "Set screensaver timeout to 10 minutes..."
  defaults -currentHost write com.apple.screensaver idleTime 600

  echo "Configuring IDE preferences..."
  setup_pivotal_ide_prefs

  echo "updating all git repos to use 'git co-author'"
  export GIT_DUET_CO_AUTHORED_BY=0
  find ~/workspace/ -type d -name '.git' -exec sh -c 'cd {} && cd .. && git duet > /dev/null && git init' \;

  echo "Workstation setup complete — open a new window to apply all settings! 🌈"
}

clone_if_not_exist() {
  local remote=$1
  local dst_dir="$2"
  local branch_name="${3:-master}"
  echo "Cloning $remote into $dst_dir"
  if [[ ! -d $dst_dir ]]; then
    if [[ -n $branch_name ]]
      then
	git clone --branch "$branch_name" "$remote" "$dst_dir"
      else
        git clone "$remote" "$dst_dir"
    fi
  fi
}

brew_all_the_things() {
  # TODO: Add retry logic around this instead
  set +e

  echo "Installing homebrew..."
  if [[ -z "$(which brew)" ]]; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

  echo "Running the Brewfile..."
  /usr/local/bin/brew update
  /usr/local/bin/brew tap Homebrew/bundle
  ln -sf $(pwd)/Brewfile ${HOME}/.Brewfile
  /usr/local/bin/brew bundle --global
  /usr/local/bin/brew bundle cleanup

  set -e
}

install_gpg() {
  echo "Installing gpg..."
  if ! [[ -d "${HOME}/.gnupg" ]]; then
    mkdir "${HOME}/.gnupg"
    chmod 0700 "${HOME}/.gnupg"

  cat << EOF > "${HOME}/.gnupg/gpg-agent.conf"
default-cache-ttl 3600
pinentry-program /usr/local/bin/pinentry-mac
enable-ssh-support
EOF

    gpg-connect-agent reloadagent /bye > /dev/null
  fi
}

install_vimfiles() {
  echo "Updating pip..."
  pip3 install --upgrade pip

  echo "Installing python-client for neovim..."
  pip3 install neovim

  echo "Adding yamllint for neomake..."
  pip3 install -q yamllint

  if [[ -f ${HOME}/.config/vim ]]; then
    echo "removing ~/.config/vim dir && ~/.config/nvim"
    rm -rf "${HOME}/.config/vim"
    rm -rf "${HOME}/.config/nvim"
    rm -rf "${HOME}/*.vim"
  else
    clone_if_not_exist https://github.com/luan/nvim "${HOME}/.config/nvim"
  fi

  echo "Adding configuration to nvim..."
  mkdir -p "${HOME}/.config/nvim/user"
  ln -sf "$(pwd)/nvim_config/after.vim" "${HOME}/.config/nvim/user/after.vim"
  ln -sf "$(pwd)/nvim_config/plug.vim" "${HOME}/.config/nvim/user/plug.vim"

  echo "Copy snippets..."
  mkdir -p ${HOME}/.vim/UltiSnips

  echo "Symlink the go.snippets to .vim/UltiSnips..."
  ln -sf $(pwd)/go.snippets ${HOME}/.vim/UltiSnips
}

install_sshb0t() {
  latest_tag=$(curl -s https://api.github.com/repos/genuinetools/sshb0t/releases/latest | jq -r .tag_name)

  # If the curl to the github api fails, use latest known version
  if [[ "$latest_tag" == "null" ]]; then
    latest_tag="v0.3.5"
  fi

  # Export the sha256sum for verification.
  sshb0t_sha256=$(curl -sL "https://github.com/genuinetools/sshb0t/releases/download/${latest_tag}/sshb0t-darwin-amd64.sha256" | cut -d' ' -f1)

  # Download and check the sha256sum.
  curl -fSL "https://github.com/genuinetools/sshb0t/releases/download/${latest_tag}/sshb0t-darwin-amd64" -o "/usr/local/bin/sshb0t" \
    && echo "${sshb0t_sha256}  /usr/local/bin/sshb0t" | shasum -a 256 -c - \
    && chmod a+x "/usr/local/bin/sshb0t"

  echo "sshb0t installed!"

  sshb0t --once \
    --user KauzClay \
    --user jeffpak \
    --user angelachin \
    --user utako \
    --user ndhanushkodi \
    --user rosenhouse \
    --user adobley \
    --user bruce-ricard \
    --user xanderstrike
}

install_ruby() {
  set -e # it's okay if this fails, we don't use ruby much
  ruby_version=2.5.5
  echo "Installing ruby $ruby_version..."
  rbenv install -s $ruby_version
  rbenv global $ruby_version
  rm -f ~/.ruby-version
  eval "$(rbenv init -)"
  echo "Symlink the gemrc file to .gemrc..."
  ln -sf $(pwd)/gemrc ${HOME}/.gemrc

  echo "Install the bundler gem..."
  gem install bundler -v 1.17.3
  BUNDLER_VERSION="$(bundler --version | cut -d' ' -f3)"
  if [[ $(echo "${BUNDLER_VERSION}" | cut -d'.' -f1) -eq '2' ]]; then
    gem uninstall bundler -v "${BUNDLER_VERSION}"
  fi
}

setup_ssh() {
  echo "Setting up SSH config"
  echo "Ignoring ssh security for ephemeral environments..."
  if [[ ! -d ${HOME}/.ssh ]]; then
    mkdir ${HOME}/.ssh
    chmod 0700 ${HOME}/.ssh
  fi

  if [[ -f ${HOME}/.ssh/config ]]; then
    echo "Looks like ~/.ssh/config already exists, overwriting..."
  fi

  cp $(pwd)/ssh_config ${HOME}/.ssh/config
  chmod 0644 ${HOME}/.ssh/config
}

install_tmuxfiles() {
  set +e
    tmux list-sessions # this exits 1 if there are no sessions

    if [ $? -eq 0 ]; then
      echo "If you'd like to update your tmux files, please kill all of your tmux sessions and run this script again."
    else
      clone_if_not_exist "https://github.com/luan/tmuxfiles" "${HOME}/workspace/tmuxfiles"
      yes | ${HOME}/workspace/tmuxfiles/install
    fi
  set -e
}

setup_git() {
  echo "Symlink the git-authors file to .git-authors..."
  ln -sf $(pwd)/git-authors ${HOME}/.git-authors

  echo "Symlink the shared.bash file into .bash_profile"
  ln -sf $(pwd)/shared.bash ${HOME}/.bash_profile

  if [[ ! $(type diff-highlight 2> /dev/null) ]]; then
      cp $(find / -name diff-highlight -type f 2> /dev/null | head -1) /usr/local/bin/
  fi

  # Don't symlink this one because `git duet` will add
  # things to it and you don't want to push these changes.
  echo "Copy the gitconfig file into ~/.gitconfig..."
  cp -rf $(pwd)/gitconfig ${HOME}/.gitconfig

  echo "Installing cred-alert-cli"
  install_credalert

  echo "Symlink the inputrc file into ~/.inputrc..."
  ln -sf $(pwd)/inputrc ${HOME}/.inputrc

  echo "Symlink global .gitignore"
  ln -sf $(pwd)/global-gitignore ${HOME}/.global-gitignore

  echo "Symlink global .git-prompt-colors.sh"
  ln -sf $(pwd)/git-prompt-colors.sh ${HOME}/.git-prompt-colors.sh
}

setup_pivotal_ide_prefs() {
  pushd ~/workspace/pivotal_ide_prefs > /dev/null
	  ./cli/bin/ide_prefs install --ide=rubymine
	  ./cli/bin/ide_prefs install --ide=goland
  popd > /dev/null
}

all_the_repos() {
  echo "Cloning all of the repos we work on..."

  # base16-shell: For the porple
  clone_if_not_exist "https://github.com/chriskempson/base16-shell" "${HOME}/.config/base16-shell"

  # Deployments Routing:  Pipelines, environment info, helpful scripts
  clone_if_not_exist "git@github.com:cloudfoundry/deployments-routing" "${HOME}/workspace/deployments-routing"

  # CF Networking Deployments: Private manifests and credentials for C2C CI
  clone_if_not_exist "git@github.com:cloudfoundry/cf-networking-deployments" "${HOME}/workspace/cf-networking-deployments"

  # Routing Datadog Config: Configure your Data 🐶
  clone_if_not_exist "git@github.com:cloudfoundry/routing-datadog-config" "${HOME}/workspace/routing-datadog-config"

  # Routing Team Checklists: Checklists (on-call, onboarding) and a kind of helpful wiki
  clone_if_not_exist "git@github.com:cloudfoundry/routing-team-checklists" "${HOME}/workspace/routing-team-checklists"

  # Networking Program Checklists: Checklists (on-call, onboarding) and a kind of helpful wiki
  clone_if_not_exist "git@github.com:cloudfoundry/networking-program-checklists" "${HOME}/workspace/networking-program-checklists"

  # Bosh Deployment: We usually use this to bump golang in our releases
  clone_if_not_exist "https://github.com/cloudfoundry/bosh-deployment" "${HOME}/workspace/bosh-deployment"

  # CF Deployment: We use it to deploy Cloud Foundries
  clone_if_not_exist "https://github.com/cloudfoundry/cf-deployment" "${HOME}/workspace/cf-deployment"

  # CF Deployment Concourse Tasks: We use it to deploy Concourses
  clone_if_not_exist "https://github.com/cloudfoundry/cf-deployment-concourse-tasks" "${HOME}/workspace/cf-deployment-concourse-tasks"

  # CF Acceptance Test: 🐱 🐱  or CATS. Happy path integration tests for CF
  clone_if_not_exist "https://github.com/cloudfoundry/cf-acceptance-tests" "${GOPATH}/src/code.cloudfoundry.org/cf-acceptance-tests"

  # CF Smoke Tests: Quick test that pretty much just pushes an app to verify a successful deployment of CF
  clone_if_not_exist "https://github.com/cloudfoundry/cf-smoke-tests" "${GOPATH}/src/code.cloudfoundry.org/cf-smoke-tests"

  # NATS Release: Inherited from Release Integration. We now own this release, which deploys NATS, which is used in CF
  clone_if_not_exist "https://github.com/cloudfoundry/nats-release" "${GOPATH}/src/code.cloudfoundry.org/nats-release"

  # Istio Acceptance Tests: Used to verify Cloud Foundry integration with Istio using real environments and real components
  clone_if_not_exist "https://github.com/cloudfoundry/istio-acceptance-tests" "${GOPATH}/src/code.cloudfoundry.org/istio-acceptance-tests"

  # Istio Release: BOSH release used to deploy Istio, Envoy, Copilot
  clone_if_not_exist "https://github.com/cloudfoundry/istio-release" "${GOPATH}/src/code.cloudfoundry.org/istio-release"

  # Istio Workspace: Use this if you want to work outside of your GOPATH and spin up a Vagrant VM for testing (see istio_docker())
  clone_if_not_exist "https://github.com/cloudfoundry/istio-workspace" "${HOME}/workspace/istio-workspace"

  # Routing API CLI: Used to interact with the Routing API, which can be found in Routing Release
  clone_if_not_exist "https://github.com/cloudfoundry/routing-api-cli" "${GOPATH}/src/code.cloudfoundry.org/routing-api-cli"

  # CF Networking CI: the DEPRECATED CI repo for Container Networking Release CI
  clone_if_not_exist "https://github.com/cloudfoundry/cf-networking-ci" "${HOME}/workspace/cf-networking-ci"

  # Toque Scaling: Scaling tests in the C2c CI
  clone_if_not_exist "https://github.com/cf-container-networking/toque-scaling" "${HOME}/workspace/toque-scaling"

  # Toque Test Helpers: Fixtures for the toque scaling tests
  clone_if_not_exist "https://github.com/cf-container-networking/toque-test-helpers" "${HOME}/workspace/toque-test-helpers"

  # CF Networking Release: BOSH release for policy-based container networking in Cloud Foundry
  clone_if_not_exist "https://github.com/cloudfoundry/cf-networking-release" "${HOME}/workspace/cf-networking-release"

  # Routing Perf Release: Used to run performance tests against Routing Release
  clone_if_not_exist "https://github.com/cloudfoundry/routing-perf-release" "${GOPATH}/src/code.cloudfoundry.org/routing-perf-release"

  # Routing Release: BOSH Release home to the Gorouter, TCP router, and a bunch of other routing related things. Spelunk! Refactor!
  clone_if_not_exist "https://github.com/cloudfoundry/routing-release" "${HOME}/workspace/routing-release"

  # Routing Sample Apps: Mostly used by developers and PMs for debugging and acceptance. If you don't see what you need, make it and add extensive documentation.
  clone_if_not_exist "https://github.com/cloudfoundry/routing-sample-apps" "${HOME}/workspace/routing-sample-apps"

  # Docs Book CloudFoundry: You'll need this if you want to make any documentation changes for the Cloud Foundry docs site.
  clone_if_not_exist "https://github.com/cloudfoundry/docs-book-cloudfoundry" "${HOME}/workspace/docs-book-cloudfoundry"

  # Docs Running CF: You'll need this if you want to run a docs site locally to make sure your changes are OK.
  clone_if_not_exist "https://github.com/cloudfoundry/docs-running-cf" "${HOME}/workspace/docs-running-cf"

  # Istio Scaling: Used to test the scalability of Istio in a Cloud Foundry deployment
  clone_if_not_exist "https://github.com/cloudfoundry/istio-scaling" "${GOPATH}/src/code.cloudfoundry.org/istio-scaling"

  # Community Bot: an ever changing tool to help with our community responsibilities
  clone_if_not_exist "https://github.com/cf-routing/community-bot" "${GOPATH}/src/github.com/cf-routing/community-bot"

  # Zero Downtime Release: BOSH release for testing app availability
  clone_if_not_exist "https://github.com/cf-routing/zero-downtime-release" "${HOME}/workspace/zero-downtime-release"

  # Diego Release: BOSH release for container scheduling for Cloud Foundry Runtime
  clone_if_not_exist "https://github.com/cloudfoundry/diego-release" "${HOME}/workspace/diego-release"

  # Capi Release: BOSH release for the Cloud Controller API
  clone_if_not_exist "https://github.com/cloudfoundry/capi-release" "${HOME}/workspace/capi-release"

  # Garden RunC Release: BOSH release for Garden RunC
  clone_if_not_exist "https://github.com/cloudfoundry/garden-runc-release" "${HOME}/workspace/garden-runc-release"

  # Silk: Open-source, CNI-compatible container networking fabric
  clone_if_not_exist "https://github.com/cloudfoundry/silk" "${GOPATH}/src/code.cloudfoundry.org/silk"

  # Cf Networking Helpers: Helpers for running tests?
  clone_if_not_exist "https://github.com/cloudfoundry/cf-networking-helpers" "${HOME}/workspace/cf-networking-helpers"

  # Istio Sample Apps
  clone_if_not_exist "git@github.com:GoogleCloudPlatform/istio-samples.git" "${HOME}/workspace/istio-samples"

  # CF K8S Networking
  clone_if_not_exist "https://github.com/cloudfoundry/cf-k8s-networking" "${HOME}/workspace/cf-k8s-networking"

  # Eirini
  clone_if_not_exist "https://github.com/cloudfoundry-incubator/eirini" "${HOME}/workspace/eirini"

  # Eirini BOSH Release
  clone_if_not_exist "https://github.com/cloudfoundry-community/eirini-bosh-release" "${HOME}/workspace/eirini-bosh-release"

  # Networking OSS Deployments
  clone_if_not_exist "git@github.com:cloudfoundry/networking-oss-deployments.git" "${HOME}/workspace/networking-oss-deployments"

  # Pivotal Only ==============================================================================================

  # Routing Support Notes: List of support tickets, past and present, and a handy template to start your own.
  clone_if_not_exist "git@github.com:pivotal/routing-support-notes" "${HOME}/workspace/routing-support-notes"

  # Scripts for generating Istio config for PKS Routing
  clone_if_not_exist "git@github.com:pivotal/k8s-istio-resource-generator" "${GOPATH}/src/github.com/pivotal/k8s-istio-resource-generator"

  # PKS Service Mesh repo
  clone_if_not_exist "git@github.com:pivotal/ingress-router" "${GOPATH}/src/github.com/pivotal/ingress-router"

  # Pivotal Networking CI -- pipeline and tasks for pivotal ci
  clone_if_not_exist "git@github.com:pivotal/pivotal-networking-ci" "${GOPATH}/src/github.com/pivotal/pivotal-networking-ci"

  # PKS Networking Env Metadata -- env info for pivotal ci
  clone_if_not_exist "git@github.com:pivotal/pks-networking-env-metadata" "${GOPATH}/workspace/pks-networking-env-metadata"

  # Norsk Config -- for OSL
  clone_if_not_exist "git@github.com:pivotal-cf/norsk-config" "${HOME}/workspace/norsk-config"

  # Norsk repo for running OSL pipeline tasks locally
  clone_if_not_exist "git@github.com:pivotal-cf/norsk.git" "${HOME}/workspace/norsk"

  # Istio Envoy OSL scripts
  clone_if_not_exist "git@github.com:pivotal/istio-envoy-osl.git" "${HOME}/workspace/istio-envoy-osl"

  # Pivotal Intellij IDE Preferences
  clone_if_not_exist "git@github.com:pivotal-legacy/pivotal_ide_prefs.git" "${HOME}/workspace/pivotal_ide_prefs"
}

function install_credalert() {
  # https://sites.google.com/a/pivotal.io/cloud-foundry/process/security/cred-alert-cli-instructions
  clone_if_not_exist "https://github.com/pivotal-cf/git-hooks-core.git" "${HOME}/workspace/git-hooks-core" "team/networking"

  # hook is added in gitconfig

  # install binary
  curl -O https://s3.amazonaws.com/cred-alert/cli/current-release/cred-alert-cli_darwin
  install cred-alert-cli_darwin /usr/local/bin/cred-alert-cli
  rm cred-alert-cli_darwin
}

main "$@"
