#!/usr/bin/env bash

set -eu

. "$HOME/.asdf/asdf.sh"

plugins=('adr-tools'
'cf'
'concourse'
'dep'
'fd'
'golang'
'helm'
'kubectl'
'kustomize'
'neovim'
'nodejs'
'packer'
'protoc'
'ruby'
'ripgrep'
'shellcheck'
'sqlite'
'terraform'
'yarn'
)

asdf plugin-add istioctl
asdf plugin-add kapp https://github.com/k14s/asdf-k14s.git
asdf plugin-add ytt https://github.com/k14s/asdf-k14s.git
for plugin in ${plugins[*]}
do
  asdf plugin-add "${plugin}"
done

bash /home/pivotal/.asdf/plugins/nodejs/bin/import-release-team-keyring

cd "$HOME"

plugins+=(kapp ytt)

asdf install istioctl 1.4.5
echo "istioctl 1.4.5" >> "$HOME/.tool-versions"

for plugin in ${plugins[*]}
do
  asdf install "${plugin}" latest
  version=$(asdf list "${plugin}")
  echo "${plugin} ${version}" >> "$HOME/.tool-versions"
done

rm -rf /tmp/*
