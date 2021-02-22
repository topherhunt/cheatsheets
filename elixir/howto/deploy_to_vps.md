# Steps to deploy a Phoenix app to a new Scaleway VPS


* Create a Scaleway or DigitalOcean instance.

* Give it an alias in `~/.ssh/config`, eg. `triggers-prod`.
  (NOTE: The following steps use the `ubuntu` user, not `root`. I could adjust these steps to only access the server as `root`, which lets us bypass the port forwarding and certfile chmod steps.)

* Point my domain/subdomain to this instance's IP (an `A` record should be enough)

* SSH into it

```sh
sudo apt-get update && sudo apt-get upgrade -y
# Erlang dependencies
sudo apt-get install -y build-essential automake libncurses5-dev libssl-dev unzip
# NPM dependencies
sudo apt-get install -y python-minimal

# Install Postgres
# NOTE: Use `mix phx.gen.secret` to generate the password; note it in `config/secrets.exs`
sudo apt-get install -y postgresql-10
createdb $(whoami)
sudo -u postgres psql -d postgres -c "CREATE ROLE ubuntu SUPERUSER CREATEDB LOGIN PASSWORD 'REPLACE_ME';"

# Create a Github deploy key for this repo, and paste in the key generated below:
ssh-keygen -t ed25519 -C "triggers-prod@localhost"
cat ~/.ssh/id_ed25519.pub

# Clone the repo
git clone GITHUB_REPO_URL
cd MY_REPO_FOLDER

# Install asdf:
# * Follow steps at: https://asdf-vm.com/#/core-manage-asdf
asdf plugin-add elixir
asdf plugin-add erlang
asdf plugin-add nodejs
# Erlang build takes a while, so I can start writing secrets.exs while I'm waiting.
asdf install
# * Check for errors and check that the correct versions are installed. If Erlang build
#   showed OpenSSL-related errors, see https://github.com/asdf-vm/asdf-erlang and fix.
```

* Write `secrets.exs` which sets all production env vars
  - set up SMTP email sending credentials (eg. from a Mailgun account)
  - set up a Rollbar account if needed, and add that ROLLBAR_ACCESS_TOKEN
  - Set `SSL_KEYFILE_PATH` (to privkey.pem) and `SSL_CERTFILE_PATH` (to fullchain.pem)

* `mix deps.get && MIX_ENV=prod mix compile`
  - Ensure no compile errors

* Set up LetsEncrypt:
  (See also: https://certbot.eff.org/lets-encrypt/ubuntubionic-other)
  - `sudo snap install core; sudo snap refresh core`
  - `sudo snap install --classic certbot`
  - `sudo ln -s /snap/bin/certbot /usr/bin/certbot`
  - `sudo certbot certonly --standalone` (ensure the webserver is stopped first)
  - `sudo chown -R ubuntu /etc/letsencrypt/` (ensure the ubuntu user can see the cert files)
  - In `config/secrets.exs`, set `SSL_KEYFILE_PATH` (to privkey.pem) and `SSL_CERTFILE_PATH` (points to fullchain.pem). Example path: `/etc/letsencrypt/live/triggers.topherhunt.com/privkey.pem`
  - See also: https://phoenixframework.readme.io/docs/configuration-for-ssl
  - See also: https://hexdocs.pm/plug_cowboy/Plug.Cowboy.html#https/3

* Forward traffic from ports 80 and 443 to 4001 where Phoenix can listen for it:
  - `sudo iptables -t nat -I PREROUTING -p tcp --dport 443 -j REDIRECT --to-ports 4001`
  - To list all routing rules: `sudo iptables -t nat --list --line-numbers`
  - To delete / disable a rule: `sudo iptables -t nat -D PREROUTING 1`
  - See also my cheatsheet `networks.md`

* Start the production app
  - `npm install --prefix assets/`
  - `npm run deploy --prefix assets/`
  - `MIX_ENV=prod mix phx.digest`
  - `MIX_ENV=prod mix ecto.create`
  - `MIX_ENV=prod mix ecto.migrate`
  - `MIX_ENV=prod mix phx.server`

* Set up Papertrail log capture
  - Ensure the prod server writes logs to log/prod.log
  - Set up a Papertrail account
  - Install Papertrail's remote_syslog (see https://papertrailapp.com/systems/setup?type=app&platform=unix)
  - Start the remote_syslog service
  - TODO: Should I configure remote_syslog to autostart on reboot?
  - Ensure logs are appearing in Papertrail

* Set up an UptimeRobot monitor

* Smoke-test that everything is wired up
  - Site is reachable
  - http:// access redirects to https://
  - Emails are sent correctly
  - Backend errors are reported to Rollbar
  - Frontend JS errors are reported to Rollbar
  - Logs are routed to Papertrail




[TO INTEGRATE]

* Add Papertrail integration

* Add an UptimeRobot monitor


## How to renew the LetsEncrypt certificate

* `sudo certbot renew --dry-run`
* Copy the certfiles into the locations specified in the Phoenix config


## Useful references:

LetsEncrypt: https://letsencrypt.org/getting-started/ and https://certbot.eff.org/lets-encrypt/ubuntubionic-other

Phoenix official deployment guide: https://hexdocs.pm/phoenix/deployment.html#putting-it-all-together

Using Docker to deploy a Phoenix app on EC2: https://blog.altendorfer.at/2017/elixir/dev/andi/2017/12/24/deploying-elixirphoenixectopostgres-project-at.html

Deploying a Rails app on a DigitalOcean instance "the hard way": https://www.thegreatcodeadventure.com/deploying-rails-to-digitalocean-the-hard-way/
