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
  - ideally run this foregrounded inside a tmux window or background it somehow
  - `cd` to `~/setup/pan-globalprotect-okta`
  - run `python3 gp-okta.py gp-okta.conf`
  - log in to Okta from the CLI (only SMS, Google Auth, or Push to Login TFA supported)
- Secrets of the shared.bash without breaking your machine
- run `code-server --port 4567` and use VS Code at `localhost:4567`
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
- Docker support inside the container is not yet tested
