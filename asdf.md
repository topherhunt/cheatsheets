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


## Installing Erlang on Linux (Ubuntu)

Do steps at https://github.com/asdf-vm/asdf-erlang#before-asdf-install before installing.

Watch out for any errors during the Erlang install, esp. messages like "required development package 'blah' is not installed". If you see these, you'll need to install the required build tools first. On Ubuntu Linux for example, I needed to run: `sudo apt-get install build-essential automake libncurses5-dev libssl-dev`. (Warnings related to odbc, java, wx, and documentation can be safely ignored.)

Important: If the Erlang installation prints any warnings about missing OpenSSL, you need to `asdf uninstall erlang` then recompile with the `ERLANG_OPENSSL_PATH` var set, e.g.:

    ERLANG_OPENSSL_PATH="/usr/local/opt/openssl" asdf install erlang 21.1

Alternatively, give the openssl path (the directory, not a symlink) to the kerl build flag:

    KERL_CONFIGURE_OPTIONS="--with-ssl=/usr/local/Cellar/openssl@1.1/1.1.1h" asdf install erlang 23.1.4


## Installing Erlang on Mac OSX

Useful references:
  - https://github.com/asdf-vm/asdf-erlang#before-asdf-install
  - https://github.com/asdf-vm/asdf-erlang/issues/157
  - https://github.com/asdf-vm/asdf-erlang/issues/158
  - https://github.com/asdf-vm/asdf-erlang/issues/82#issuecomment-635007093
  - https://github.com/kerl/kerl/issues/320#issuecomment-545636258

**Note**: Asdf installers try to build Erlang from source, but it's super tricky to build Erlang on latest OSX. Instead, try installing a precompiled Erlang binary from homebrew. `brew search erlang` will list the available versions. In my testing, this Erlang correctly found a compatible OpenSSL.
