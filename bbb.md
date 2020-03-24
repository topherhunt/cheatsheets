# BigBlueButton

References:

  * https://demo.bigbluebutton.org/gl/
  * https://docs.bigbluebutton.org/2.2/install.html
  * https://github.com/bigbluebutton/bbb-install
  * https://docs.bigbluebutton.org/2.2/customize.html

Possible hosts:

  * https://www.scaleway.com/en/pricing/ - way cheaper than DO or Ionos
  * https://www.ionos.com/servers/dedicated-servers - metal (starts at €70/mo)
  * DigitalOcean - simple starting point


## Setting up a test instance of BBB

  * Set up a DO droplet / EC2 instance / Scaleway VPS / Ionos metal server
    - Must be Ubuntu 16.04
    - Must have 4+ GB RAM
    - Preferably 4+ CPU cores
    - Set up block storage (also must set the -m path below!)
    - EU region
    - Use my standard ssh key

  * Set up a domain name (these steps use *bbb-test.topherhunt.com*) that points to that server's IP.
    - A record for that subdomain, pointing to that IP

  * ssh root@NEW_SERVER_IP

  * If on Scaleway and using a block storage volume, format and mount it:
    - More info: https://www.scaleway.com/en/docs/attach-and-detach-a-volume-to-a-bare-metal-instance/
    - run `lsblk` to list all volumes available.
    - Assuming that the block volume is called `sda`:
    - `mkfs -t ext4 /dev/sda` to format the volume (only if not already formatted!)
    - `mkdir /mnt/data`
    - `mount /dev/sda /mnt/data`
  * Then you need to set up systemd to auto mount the block volume on restart:
    - TODO: Next time, try this briefer approach: https://www.scaleway.com/en/docs/how-to-mount-and-format-a-block-volume/#-Using-fstab-for-Persistent-Mounting
    - Get the volume UUID: `blkid | grep sda`
    - `vi /etc/systemd/system/mnt-data.mount` and enter the following:

      ```
      [Unit]
      Description=Mount Block Volume at boot

      [Mount]
      What=UUID="ENTER_THE_VOLUME_UUID"
      Where=/mnt/block
      Type=ext4
      Options=defaults

      [Install]
      WantedBy=multi-user.target
      ```

    - `systemctl daemon-reload`
    - `systemctl start mnt-data.mount`
    - `systemctl enable mnt-data.mount`

  * Run this command to install all dependencies, BBB, SSL, and GreenLight:
    * (note the domain, email, and -m path option)
    * `wget -qO- https://ubuntu.bigbluebutton.org/bbb-install.sh | bash -s -- -v xenial-220 -s bbb-test.topherhunt.com -e hunt.topher@gmail.com -g -m /mnt/data/`
    * See https://github.com/bigbluebutton/bbb-install for more options.

  * Adjust config to reflect my standard usage:
    - `vi /usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml` and update these settings:
      - listenOnlyMode = false
      - autoShareWebcam = true
      - autoSwapLayout = true
      - Remove the "High definition" entry under cameraProfiles
      - captions.enabled = false
      - chat.enabled = false
    - (Ideally chat would be enabled, but the user sidebar would be hidden by default.)
    - `sudo bbb-conf --restart` to apply the settings changes

  * Set up Google auth:
    - Follow steps at https://docs.bigbluebutton.org/greenlight/gl-config.html#google-oauth2
    - Greenlight env config is in `~/greenlight/.env`
    - After editing .env, `reboot` so the changes will take effect.

  * Test that it's all working correctly
    - https://bbb-test.topherhunt.com/


## Commands & config

  * `sudo bbb-conf --status`
  * `sudo bbb-conf --check` - list config, problems, and any logged errors
  * `sudo bbb-conf --secret` - display info on how to connect a frontend
  * `sudo bbb-conf --restart`
  * By default, data is stored in `/var/bigbluebutton/`. The -m option above can override that and create a symlink instead.
  * HTML5 client settings live at `/usr/share/meteor/bundle/programs/server/assets/app/config/settings.yml`, and `/usr/share/bbb-web/WEB-INF/classes/bigbluebutton.properties`, and other places probably.
  * The default presentation shown is `default.pdf`. Unfortunately I don't see a way to hide the presentation by default.


## Thoughts for a production hosted BBB server setup

  - I'll need to modify Greenlight to be a subscription service:
    - Adjust theming, branding, and wording on the homepage
    - For a beta period of 2 weeks, anyone can host unlimited meetings for free
    - Users can sign up for free, but running meetings will be restricted to paying subscribers starting on REF. Or maybe your first meeting is free, but for regular use you need to subscribe.

  - I'll need thorough monitoring so I can answer questions like:
    - are we near CPU / RAM / disk space capacity?
    - how many meetings are happening, when, and how long are they?
    - can I configure the server to send me a daily email with that day's stats?

  - Need a safe, easy process for transferring block volume data to a larger volume

Tech & config thoughts:

  - disable highest-bandwidth video setting
  - bandwidth monitoring: https://www.tecmint.com/bmon-network-bandwidth-monitoring-debugging-linux/ and http://www.ubuntugeek.com/bandwidth-monitoring-tools-for-ubuntu-users.html
  - Every 1 min, log a series of system stats in csv format (disk space used in MB; mem used in MB; CPU load; current bandwidth usage; # active meetings if available)
  - you can set up webhooks to watch for BBB events (e.g starting a meeting, ending a meeting)

Scaling thoughts:

  - https://github.com/blindsidenetworks/scalelite - scaleable load balancer for BBB
  - https://docs.bigbluebutton.org/support/faq.html#how-many-simultaneous-users-can-bigbluebutton-support
  - bandwidth requirements: https://docs.bigbluebutton.org/support/faq.html#bandwidth-requirements
  - A server that meets minimum specs can host around 150 simultaneous users. It's not recommended to have over 100 users in the same meeting.
  - Generally when CPU load reaches 80%, the audio will start to degrade.
  - A 1-hour meeting recording will weigh around 300 MB.
