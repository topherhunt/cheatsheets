# GoatCounter self-hosting setup

https://www.goatcounter.com/ https://github.com/arp242/goatcounter


## Setup steps

- Create a VPS eg. from AWS EC2 or DigitalOcean.
- SSH in (DigitalOcean auto adds your public key if you've provided it)
- `wget https://github.com/arp242/goatcounter/releases/download/v2.2.3/goatcounter-dev-linux-amd64.gz`
- `gzip -d goatcounter-dev-linux-amd64.gz`
- `mv goatcounter-dev-linux-amd64 goatcounter`
- `chmod ugo+x goatcounter`
- `./goatcounter help ( |db|serve|listen)` to display usage instructions
- `./goatcounter db create site -vhost 164.92.211.236 -user.email hunt.topher@gmail.com`
- `ufw allow 80`
- `ufw allow 443`
- Use `nc -lk 0.0.0.0 80` and `...443` to confirm that the ports are open to outside world
- `./goatcounter serve -listen :443 -tls acme,rdr` - start the server.
- TODO: ^ This doesn't work. Maybe it's because my vhost isn't a proper subdomain?



- `tmux` to start a persisted session
- 
