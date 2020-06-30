# Dockerfile for networking-workspace

## Usage

To start the container, run `./start-container.sh`.

To enter a login shell for the container, run `./login-container.sh`.

You can exit the shell at any time without exiting the container.

To actually kill the container, run `./kill-container.sh`.

The `start-container.sh` script will assume you have all your project folders
inside `~/workspace` on your host machine and bind-mount the workspace folder
into the container.

The script also automatically binds port 4567 inside the container to the
host network.

`start-container.sh` will pass additional flags to the `docker run` command itself.


## Features

- Vim and Tmux are supported
- Many CLI tools are preinstalled (bosh, cf, pks CLI, om CLI, kubectl, fly, etc.)
- Updated to most recent version of golang, ruby
- VPN support
- Secrets of the shared.bash without breaking your machine
- code-server
- SSH agent forwarding for Linux-based hosts

## Known Issues:

- There might be some weird errors for Vim or Tmux
   - They don't seem to affect anything
- SSH agent forwarding doesn't work on Mac OSX
  - This is because OSX does not allow bind mounts to the SSH auth sock for some reason
- VPN access does not support alternative TFA methods
  - Currently there isn't a method of getting an OAuth token from Okta if we
    use the Browser-based flow
- Error messages show up when setting up the VPN: `Cannot open "/proc/sys/net/ipv4/route/flush": Read-only file system`
  - Apparently it's not really an issue. You can use the VPN as normal.
- Permission denied on bind-mounted workspace folder?
  - The container expects the UID of the UNIX user on your host to be 501.
  - To fix this, either change the UID of the user on your host or change
    the UID of the user inside the container once inside. You may have to
    login to the container as root.

## Workflows

### Pivotal VPN
  Ideally run this foregrounded inside a tmux window or background it somehow:
  - `cd` to `~/setup/pan-globalprotect-okta`
  - run `python3 gp-okta.py pivotal.conf`
  - log in to Okta from the CLI (only SMS, Google Auth, or Push to Login TFA supported)

### VMware VPN
  Run `sudo openconnect --protocol gp https://gpu.vmware.com` and follow the
  instructions. The login process is kind of finicky so you might have to try
  again or use Biometric authentication.

### Connecting to container's VPN from remote
  In the container, create a SOCKS5 proxy by running `ssh -D 0.0.0.0:4568 pivotal@localhost`.
  If you've used the `./start-container.sh`, port 4568 should be forwarded by
  docker. In this case, you can now use `localhost:4568` as a SOCKS5 proxy. This
  proxy should now give you access to what is accessible by the VPN.

### VS Code
  Run `code-server --port 4567` and use VS Code at `localhost:4567`

### Using Docker or creating a local Kubernetes cluster
  Assuming you've used the `start-container.sh` script, you should
  be able to use Docker inside the container (but it connects
  to the host's Docker socket).

  To create a local Kubernetes cluster, run `kind create cluster` and
  follow the instructions on the prompt. Check out the
  [kind documentation](https://kind.sigs.k8s.io/docs/user/quick-start/)
  for more info.
