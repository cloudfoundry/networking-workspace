# workspace configuration
simple bash scripts for workstation setup

## configuring new workstations for inter- and intra- office SSH-ing

pairs will have trouble easily SSHing on to your machine if it's brand new.

### solve this problem by sending an ask ticket

```
Hello IT friends,

In the past, IT friends have been nice enough to move all of our team's machines to the CF vlan and update the DNS entries for all of our machines in SF and LA.
We've gotten new machines since then, and we'd like to be able to SSH on to each other's workstations so we can continue our usual workflow.
Could you please help us out?

Here's a list of our machines:

SF:
compton
dakota
lyon
bayside
vicente
haight
zorro
[other machines you might want to add]

LA:
labrea
crenshaw
doheny
amherst
victory
imperial
corley
larchmont

Happy to answer any follow up questions you might have.

Sincerely,
the Networking Program
```
## installation
on a freshly imaged machine:

- Ensure your GitHub SSH key is authorized for use in the `pivotal` org
  - Ensure the "SSO" button [on this page](https://github.com/settings/keys) is
    green

- open **Terminal**, load your SSH key and run
  ```
  sudo xcodebuild -license  # follow the interactive prompts
  mkdir -p ~/workspace
  cd ~/workspace
  git clone https://github.com/cloudfoundry/networking-workspace
  networking-workspace
  cd networking-workspace
  ./install.sh
  ```

- If you encounter problems with the script, fix them and re-run!

- Launch Spectacle and follow instructions to configure it at boot

To load iTerm preferences, point to this directory under `iTerm2` >
`Preferences` > `Load preferences from a custom folder or URL`.

## patterns and assumptions
- keep it simple
- declarative and idempotent
- install as much as possible via brew
- spectacle for window management
- [luan vim](https://github.com/luan/nvim) and [luan
  tmux](https://github.com/luan/tmuxfiles)
- remote pair with [ssh+tmux+zoom](./REMOTE_PAIRING.md)

## repositories
- a full list can be found [here](https://github.com/cloudfoundry/networking-workspace/commit/0d7b5ab04a81b716626ed4f63aacd6ee67aff1df#diff-3fbb47e318cd8802bd325e7da9aaabe8R276)
- we have a [fork of istio](https://github.com/cloudfoundry/istio) that we use to make PRs to upstream istio

# Troubleshooting

## Both Co-Authored-By and Signed-Off-By in commit message

You must manually remove the `/.git/hooks/prepare-commit-msg` file in each repo
and then run `git init` to complete opting out of using `Co-Authored-By`.
