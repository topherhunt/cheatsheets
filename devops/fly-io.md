# Fly.io

## Useful docs

- https://fly.io/docs/elixir/getting-started/
- https://fly.io/docs/reference/secrets/
- https://fly.io/docs/postgres/
- https://fly.io/docs/postgres/getting-started/what-you-should-know/

## Common commands

```sh
# Init a new app
fly launch

# Tail your application logs
fly logs

# App deployment details
fly status

# Database deployment details
fly status -a hello_elixir-db

# Deploy the application after making changes
fly deploy

# Create a Postgres DB tunnel
# (then connect at postgres:PASSWORD@localhost:5433/walkaround-prod)
fly proxy 5433:5432 -a walkaround-prod-db
```

## Elixir / Phoenix app deploy

Following https://fly.io/docs/elixir/getting-started/ .

- Install flyctl
- `fly launch`
- Copy the Postgres DB credentials somewhere safe
- Edit `Dockerfile` if needed, to add any runtime dependencies like ffmpeg
- Any app config that references env vars should be moved to runtime.exs
- In `config.exs`, set application `mix_env` to equal `Mix.env()` since the live app wont' be able to access Mix.env directly
- `fly deploy`
- Smoke-test it
