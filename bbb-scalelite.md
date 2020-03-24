# How to set up BBB with Scalelite load balancer

* Create & set up the Postgres instance
  - min. 2 CPU cores, 2 GB RAM
  - Name and FQDN should be like: bbb-lb-postgres.topherhunt.com
  - SSH in
  - `deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main`
  - `wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -`
  - `sudo apt-get update`
  - `sudo apt-get install -y postgresql-11`
  - (TODO) Ensure it's started
  - (TODO) Configure all PG accounts to be secured
  - (TODO) Set up the PG server to listen for remote connections:
    https://bosnadev.com/2015/12/15/allow-remote-connections-postgresql-database-server/
  - (TODO) Ensure I can connect from anywhere

* Create & set up the Redis instance
  - min. 2 CPU cores, 0.5GB RAM
  - Name and FQDN should be like: bbb-lb-redis.
  - (TODO) Install Redis
  - (TODO) Ensure persistence is enabled
  - Configure it so I can connect to Redis from anywhere

* Create & set up each BBB instance
  - The pool should have at least 3 instances.
  - min. 4 CPU cores, 8 GB RAM
  - Name and FQDN should be like: bbb-lb-pool1., etc.
  - install BBB using the script (no Greenlight, no custom data path):
    `wget -qO- https://ubuntu.bigbluebutton.org/bbb-install.sh | bash -s -- -v xenial-220 -s bbb-pool1.topherhunt.com -e hunt.topher@gmail.com`
  - (TODO) Connect to the NFS share (and ensure it connects on mount. using fstab?)
    https://linuxize.com/post/how-to-mount-an-nfs-share-in-linux/
  - (TODO) Set up script to move recordings to the NFS share

* Create & set up the Scalelite balancer instance
  - Name and FQDN should be like: bbb-lb-scalelite.
  - https://github.com/blindsidenetworks/scalelite/blob/master/docker-README.md
  - (TODO)
  - ...
  - Create and export the NFS shared volume
    - [TODO]
    - Notes:
      - https://github.com/blindsidenetworks/scalelite/blob/master/sharedvolume-README.md
      - See also https://www.dummies.com/computers/operating-systems/linux/how-to-share-files-with-nfs-on-linux-systems/
      - Watch out for NFS high CPU load: https://serverfault.com/a/958621/275261
      - If the scalelite server has performance issues, switch to a dedicated NFS exporter.

* Create & set up the Greenlight frontend instance
  - Name and FQDN should be like: bbb-lb-frontend.
  - https://docs.bigbluebutton.org/greenlight/gl-install.html#installing-on-a-bigbluebutton-server

* (TODO) Set up monitoring
