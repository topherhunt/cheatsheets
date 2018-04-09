# Spinning up a new vanilla Phoenix app

Ensure you're on Elixir v1.6+ (compiled on Erlang OTP v20+) and have the Phoenix Mix package installed.

`mix phx.new vanilla` (say `y` to install dependencies)
`git init .`
`git add --all; git commit -m "Create fresh app"`
`mix ecto.create`

## Update `mix.exs` with common dependencies

TODO

`mix deps.get`

## Set up config and secrets

TODO

## Update .gitignore

```
# .gitignore
# App artifacts
/_build
/db
/deps
/*.ez
/assets/node_modules
/priv/static/
erl_crash.dump
*.log

# Sensitive env variables
config/secrets.exs
```


