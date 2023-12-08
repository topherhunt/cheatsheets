### Setup for disabling & enabling MacOS bluetooth on sleep/wake:

- `brew install sleepwatcher`
- `brew services start sleepwatcher`
- `brew install blueutil`
- Run `blueutil` to confirm that the utility has the needed MacOS permissions.
- Create `~/.sleep`, `~/.wakeup`, and `~/.sleepwatcher.log` content as shown below
- Run `which blueutil` and confirm that the path matches the path used in the scripts below (or update the scripts accordingly)
- `chmod 700 ~/.sleep`
- `chmod 700 ~/.wakeup`

Then close the lid, wait a few seconds, open it again, and check `~/.sleepwatcher.log`.

Contents of `~/.sleep`:

```sh
#!/bin/bash
# Sleepwatcher (Homebrew package) script that runs on sleep.
# See also: ~/.sleep, ~/.wakeup, ~/.sleepwatcher.log
/opt/homebrew/bin/blueutil --power off
/usr/sbin/networksetup -setairportpower en0 off
echo "$(date -Iseconds) -- Sleep event detected. Disabled bluetooth and wifi. Bluetooth status: $(/opt/homebrew/bin/blueutil --power). $(/usr/sbin/networksetup -getairportpower en0)" >> ~/.sleepwatcher.log
```

Contents of `~/.wakeup`:

```sh
#!/bin/bash
# Sleepwatcher (Homebrew package) script that runs on wakeup.
# See also: ~/.sleep, ~/.wakeup, ~/.sleepwatcher.log
/opt/homebrew/bin/blueutil --power on
/usr/sbin/networksetup -setairportpower en0 on
echo "$(date -Iseconds) -- Wake event detected. Enabled bluetooth and wifi. Bluetooth status: $(/opt/homebrew/bin/blueutil --power). Wifi status: $(/usr/sbin/networksetup -getairportpower en0)" >> ~/.sleepwatcher.log
```

Contents of `~/.sleepwatcher.log`:

```
# Sleepwatcher activity log. See also ~/.wakeup and ~/.sleep scripts.


```
