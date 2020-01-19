# Tmux


## What can you do with it?

- When you ssh in and want to run a command that won't die if the connection breaks, or have output that you want to preserve, start a tmux instance. Then you can always re-attach to it later if connection is lost; it will be preserved in its latest state

- Have multiple shell sessions within the same terminal window (so you don't need to manage lots of terminal tabs

- Attach a window to a session / detach from a session

- Share a shell session. 2+ people can attach to the same shell session, and watch each other type.

- When you ssh in, start up a tmux session. that way you can run commands and not care if the ssh session dies. Then you can ssh back in later from anywhere else, and re-attach to that same tmux session.

- Split the view into multiple panes

- Great for session durability & window management on a remote server


## Basic usage

All your windows (sessions) are listed in the green bar at bottom.

- `tmux` => start a new tmux session (new set of tabs)
- `tmux attach` => re-attach to the first existing tmux session
  (even if another connection is already attached!)
- `tmux list-sessions` => list all running Tmux sessions

- `ctrl-b c` => create a new window
- `ctrl-b ,` => rename this window
- `ctrl-b w` => list windows so you can switch to one
- `ctrl-b d` => detach from this tmux session (leaving it active)
- `exit` => closes the current tmux window (or the whole session if none left)
- `ctrl-b ?` => list all keybindings
- `ctrl-b [` => enter scroll mode. Now you can use the arrow keys to scroll back in the buffer.
  Press `q` to exit scroll mode.

Advanced:

- `ctrl-b p` => cycle to previous window
- `ctrl-b n` => cycle to next window
- `ctrl-b %` => split panes horizontally
- `ctrl-b "` => split panes vertically
