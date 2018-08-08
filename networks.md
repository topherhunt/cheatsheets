
## Set up a general-purpose SSH server

- Launch a tiny virtual server (e.g. EC2 instance, Ubuntu image, nano). Ensure you can access port 22 (for SSH) plus whatever port you want the server to receive HTTP requests at (e.g. 9878). Only allow SSH access via keypair.
- Add an alias (e.g. `vpn1`) to `~/.ssh/config` for easy access
- SSH into the server
- `sudo vi /etc/ssh/sshd_config` and add the following settings:
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


## Forward HTTP requests from a server, to a local machine (e.g. dev Rails server):

- Start with a general-purpose SSH server (see above)
- Check that HTTP requests reach the server: on the server run `nc -lk 9878`, make a web request to `http://your-server:9878/`, and the `nc` output should show the request. Then quit `nc`.
- Open the reverse tunnel: `ssh -R *:9878:localhost:3000 -N vpn1`
- Check that HTTP requests reach your local machine: locally run `nc -lk 3000`, make a web request to `http://your-server:9878/`, and the `nc` output should show the request. Then quit `nc`.
- Start your local server at the desired port (in this case 3000).

TODO:
- Q: How to accept / forward requests at port 80?
- Q: Can I forward to a different port than where it's received?


## Route web traffic from local machine through a server (VPN over SSH):

- Start with a general-purpose SSH server (see above)
- `ssh -ND 1024 vpn1` - this opens the SSH tunnel that you can use as the proxy
- Configure the OSX network interface to use a SOCKS V5 proxy through `localhost:1024`. Add the SSH server's IP to the "bypass" list so that the tunnel itself isn't subject to the proxy rules.
- Now verify that all your network traffic is proxied:
  - https://whatismyipaddress.com/ should think you're at that location
  - In an incognito browser session, maps.google.com should think you're at that location
  - If you abort the tunnel, you lose all internet access. If you re-open the tunnel, internet access is restored.

Caveats:

- Amazon's video streaming service will easily detect that your request is coming through a proxy, and will block access.
- To make yourself harder to identify, you can bounce between different servers and IPs as proxies.
- Some traffic (e.g. pings) apparently bypasses the SOCKS proxy regardless of your settings.


## Throttle network speed

This tool is the easiest way to throttle your network on OSX: https://www.sitespeed.io/documentation/throttle/

- `throttle` - start with default profile
- `throttle --stop` - disable
- `throttle --up 330 --down 780 --rtt 1` - enable and specify speeds