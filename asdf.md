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


## Installing Erlang on Mac OSX

Asdf/kerl likely won't be able to locate your OpenSSL install, so you'll need to specify where it should look. The following command should install OTP v23 (NOTE that OTP v24 is broken on OSX, and OTP 22-23 are incompatible with OpenSSL v3):

    # thanks to https://github.com/erlang/otp/issues/4821#issuecomment-840054607
    KERL_CONFIGURE_OPTIONS="--without-javac --with-ssl=$(brew --prefix openssl@1.1)" asdf install erlang 23.3.4.5

Useful references:
  - https://github.com/asdf-vm/asdf-erlang#before-asdf-install
  - https://github.com/asdf-vm/asdf-erlang/issues/157
  - https://github.com/asdf-vm/asdf-erlang/issues/158
  - https://github.com/asdf-vm/asdf-erlang/issues/82#issuecomment-635007093
  - https://github.com/kerl/kerl/issues/320#issuecomment-545636258


## Installing Erlang on Linux (Ubuntu)

Do steps at https://github.com/asdf-vm/asdf-erlang#before-asdf-install before installing.

Watch out for any errors during the Erlang install, esp. messages like "required development package 'blah' is not installed". If you see these, you'll need to install the required build tools first. On Ubuntu Linux for example, I needed to run: `sudo apt-get install build-essential automake libncurses5-dev libssl-dev`. (Warnings related to odbc, java, wx, and documentation can be safely ignored.)

Important: If the Erlang installation prints any warnings about missing OpenSSL/crypto, you need to `asdf uninstall erlang` then recompile with a flag to specify the OpenSSL path

    ERLANG_OPENSSL_PATH="/usr/local/opt/openssl" asdf install erlang 21.1


