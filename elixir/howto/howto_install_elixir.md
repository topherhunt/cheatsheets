# How to install Erlang & Elixir


## On OSX

Use Homebrew. Don't install the packages manually, it's super painful.

First install Erlang:

* `brew update`
* `brew install erlang`

Use Kiex to install Elixir and manage installed versions.

* Install Kiex: https://github.com/taylor/kiex
* `kiex list` - list installed Elixirs
* `kiex install 1.3.4` - install a specific Elixir version
* `kiex default 1.3.4` - set the default Elixir version (need to restart session)

Then ensure Hex PM is installed: `mix local.hex`
