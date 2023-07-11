# Systemd and journald

Basic systemd usage: https://www.thegeekdiary.com/centos-rhel-7-systemd-command-line-reference-cheat-sheet/


## Services

  * List services: `systemctl list-unit-files`

  * Check status of a service: `systemctl status cron`

  * Restart a service: `systemctl restart cerberus`

  * View config of a service: `systemctl show cerberus`

  * Edit service config: `sudo vi /etc/systemd/cerberus.service`

  * Apply edited service config: `sudo systemctl daemon-reload`

  * Adding a new service: https://www.garron.me/en/linux/add-service-systemd-systemctl.html


## Logs

  * View all logs of a service: `journalctl -u cerberus`

  * Tail the logs of a service: `journalctl -u cerberus -f`

  * List all recorded boots: `journalctl --list-boots`


## Persisting logs

  * Basic journald usage: https://www.digitalocean.com/community/tutorials/how-to-use-journalctl-to-view-and-manipulate-systemd-logs

  * Enable persistent logs without server reboot: https://www.golinuxcloud.com/enable-persistent-logging-in-systemd-journald/

  * Create the directory for persistent logs:
    `sudo mkdir -p /var/log/journal`

  * Enable persistent logs:
    - `sudo nano /etc/systemd/journald.conf`
    - Set `Storage=persistent`
