## Quick reference

```sh
# Make a curl request, printing just the headers
curl -I https://www.wvtest.com/

# Open an SSH tunnel for poor man's VPN
ssh -vND 1024 vpn1
```


## Network debugging

- `nc -vz 52.87.50.47 8008` # test whether a remote host is accessible at a port
- `nc -lk 0.0.0.0 8008 > netcat_listen.txt` # listen on a port, log all cxs to a text file
- List all listening ports and the responsible PIDs:
  - `netstat -tuplen` # (Linux)
  - `lsof -Pn | grep 3000` # (OSX - find Rails processes)
- `echo '{"text": "Test content"}' | curl -d @- http://domain.com:8000/queries.json`
  # send a test request with JSON data to verify that a JSON service is accessible

Monitor my public IP every second:
`while : ; do dig TXT +short o-o.myaddr.l.google.com @ns1.google.com ; sleep 1 ; done`


## Set up a general-purpose SSH server

- Launch a tiny VPS (eg. EC2 nano Ubuntu). Ensure you can access port 22 (for SSH) plus the port where the server will receive HTTP requests (e.g. 9878).
- In `~/.ssh/config`, add an alias (eg. `vpn1`) for easy access:

```
# Configured 2018-08-07
Host vpn1
  User ubuntu
  Hostname ec2-1234-5678.compute-1.amazonaws.com
  IdentityFile ~/.ssh/topher-aws.pem
```

- SSH into the server
- Ensure the firewall won't block ports: `sudo ufw allow 22 && sudo ufw allow 9878`
- Edit `/etc/ssh/sshd_config` to add the following settings:

```
AllowAgentForwarding yes
AllowTcpForwarding yes
PermitTunnel yes
GatewayPorts clientspecified
```

- `sudo systemctl restart sshd` - to make the settings take effect
- `exit` back to your local machine
- Now you can `ssh vpn1` to ssh in, use the `-D` flag to open a forwarding tunnel, and use the `-R` flag to set up reverse forwarding, etc.

TODO:
* Q: Are all the above setting changes required to enable traffic forwarding and reverse forwarding?


## Forward others' HTTP requests to a local server:

Use https://ngrok.com/ where possible, this is a super nice tool for forwarding to local.
`ngrok http 3000` will start a proxy server, listen for any requests, and forward them to `localhost:3000` over its tunnel.

If ngrok doesn't work, I can also forward HTTP requests to my local machine like this:

- Start with a general-purpose SSH server (see above)
- Check that HTTP requests reach the server (`nc -lk 9878`)
- Open the reverse tunnel: `ssh -vNR *:9878:localhost:3000 - vpn1`.
- Check that HTTP requests reach your local machine (`nc -lk 3000`)
- Now all requests to `http://your-server:9878/blah` should be forwarded to your local machine at `localhost:3000/blah`.


## Route web traffic from local machine through a server (VPN over SSH):

- Start with a general-purpose SSH server (see above)
- `ssh -vND 1024 vpn1` - this opens an SSH tunnel to route traffic through.
- Configure the OSX network interface to use a SOCKS V5 proxy through `localhost:1024`. Add the SSH server's IP to the "bypass" list so that the tunnel itself isn't subject to the proxy rules.
- Now verify that all your network traffic is proxied:
  - https://whatismyipaddress.com/ should think you're at that location
  - In an incognito browser session, maps.google.com should think you're at that location
  - If you abort the tunnel, you lose all internet access. If you re-open the tunnel, internet access is restored.

Caveats:

- Amazon Video will block all requests that appear to come from a VPS.
- Some traffic (e.g. pings) apparently bypasses / ignores the SOCKS proxy.


## Throttle network speed

This tool is the easiest way to throttle your network on OSX: https://www.sitespeed.io/documentation/throttle/

- `throttle` - start with default profile
- `throttle --stop` - disable
- `throttle --up 330 --down 780 --rtt 1` - enable and specify speeds


## SSH tunnel for a specific port

Start an SSH tunnel so that all traffic sent to a specific port on `localhost`, will be forwarded to your ssh server and sent to a specific host and port.

For example, let's say that my VPS server `vpn1` is on the ip whitelist to access a Postgres server `postgres-server-hostname`, but my local machine (having a dynamic ip) is not. I can run this command locally to open a tunnel to that VPS:

    ssh -NT -L 55555:postgres-server-hostname:5432 vpn1

Then locally I can run the following command to connect to the Postgres server:

    psql -h localhost -p 55555 -d my-database
