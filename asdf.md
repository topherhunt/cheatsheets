# ASDF

ASDF is a great language tool version manager.

https://asdf-vm.com/#/core-manage-asdf-vm


## Useful commands

  * `asdf plugin-add erlang`
  * `asdf plugin-add elixir`
  * `asdf plugin-add nodejs`
  * `asdf install`
  * `asdf uninstall erlang`
  * `which elixir` (should always point to the .asdf shim binary)
  * `asdf list-all erlang` (list all available versions)


## Installing Erlang

Watch out for any errors during the Erlang install, esp. messages like "required development package 'blah' is not installed". If you see these, you'll need to install the required build tools first. On Ubuntu Linux for example, I needed to run: `sudo apt-get install build-essential automake libncurses5-dev libssl-dev`. (Warnings related to odbc, java, wx, and documentation can be safely ignored.)

Important: If the Erlang installation prints any warnings about missing OpenSSL, you need to `asdf uninstall erlang` then recompile with the `ERLANG_OPENSSL_PATH` var set, e.g.:

```
ERLANG_OPENSSL_PATH="/usr/local/opt/openssl" asdf install erlang 21.1
```
