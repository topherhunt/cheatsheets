### Setup for disabling & enabling MacOS bluetooth on sleep/wake:

- `brew install sleepwatcher`
- `brew services start sleepwatcher`
- `brew install blueutil`
- Create `~/.sleep`, `~/.wakeup`, and `~/.sleepwatcher.log` content as shown below
- `chmod 700 ~/.sleep`
- `chmod 700 ~/.wakeup`

Then close the lid, wait a few seconds, open it again, and check `~/.sleepwatcher.log`.

Contents of `~/.sleep`:

```sh
#!/bin/bash
# Sleepwatcher (Homebrew package) script that runs on sleep.
# See also: ~/.sleep, ~/.wakeup, ~/.sleepwatcher.log
/opt/homebrew/bin/blueutil --power off
echo "$(date -Iseconds) -- Sleep event detected, bluetooth disabled. Bluetooth status: $(/opt/homebrew/bin/blueutil --power)" >> ~/.sleepwatcher.log
```

Contents of `~/.wakeup`:

```sh
#!/bin/bash
# Sleepwatcher (Homebrew package) script that runs on wakeup.
# See also: ~/.sleep, ~/.wakeup, ~/.sleepwatcher.log
/opt/homebrew/bin/blueutil --power on
echo "$(date -Iseconds) -- Wake event detected, bluetooth enabled. Bluetooth status: $(/opt/homebrew/bin/blueutil --power)" >> ~/.sleepwatcher.log
```

Contents of `~/.sleepwatcher.log`:

```
# Sleepwatcher activity log. See also ~/.wakeup and ~/.sleep scripts.


```