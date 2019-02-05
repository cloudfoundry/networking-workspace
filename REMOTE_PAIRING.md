# Remote pairing with ngrok + tmux

## Host

- Run `install.sh`
- Sign into [ngrok](https://dashboard.ngrok.com/get-started) with your GitHub account
- Run `ngrok authtoken $YOUR_AUTH_TOKEN`
- On Mac, make sure `System Preferences` > `Sharing` > `Remote Login` is enabled.
- Run `tmux`
- Run `whoami`. Tell the user name to your pair.
- Run `ngrok tcp 22`
- You should see a line like `tcp://0.tcp.ngrok.io:12345` in the output. Tell the port number to your pair.
- Tell your computer's password to your pair.

## Client
- Run `ssh <user name>@0.tcp.ngrok.io -p<port number>`
- Authenticate with computer's password
- Run `tmux a`
- You and your pair should now be connected to the same terminal session

## Some quick tmux shortcuts
- `<C-Space>c` creates a new tab
- `<C-Space>,` allows you to rename a tab
- `<C-Space>p` and `<C-Space>n` navigate tabs
- `<C-Space>%` creates a vertical split, `<C-Space>"` creates a horizontal split
- `<C-Space>h`, `<C-Space>j`, `<C-Space>k`, `<C-Space>l` navigate panes (like vim)
- `<C-Space>[` enters vi mode
  - You can navigate like normal vim and select text with `v` and then yank
    text with `y`
  - You can quit with `q`
- `<C-Space>]` pastes yanked text
- `<C-Space>d` detaches from the tmux session (that is, the tmux session is
  still running)
