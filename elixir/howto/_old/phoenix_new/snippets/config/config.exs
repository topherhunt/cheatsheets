# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Use H.env!/1 to fetch env variables (NOT compatible with best-practice Elixir releases)
defmodule H do
  def env!(key), do: System.get_env(key) || raise("Env var '#{key}' is missing!")
end

# Automatically load sensitive env variables if available (for dev and test)
if File.exists?("config/secrets.exs"), do: import_config("secrets.exs")

config :my_app,
  ecto_repos: [MyApp.Repo]

# Global config for the repo / db connection
config :my_app, MyApp.Repo,
  url: H.env!("DATABASE_URL"),
  # Heroku PG hobby-dev allows max 20 db connections
  pool_size: 10,
  log: false

# Configures the endpoint
config :my_app, MyAppWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: H.env!("SECRET_KEY_BASE"),
  render_errors: [view: MyAppWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: MyApp.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n"

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# By default, sent emails are captured in a local process for later inspection.
# Example:
#   MyApp.AdminEmails.unknown_heats() |> MyApp.Mailer.deliver_now()
#   Bamboo.SentEmail.all() # => a list having one %Bamboo.Email{} struct
config :my_app, MyApp.Mailer, adapter: Bamboo.LocalAdapter

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
