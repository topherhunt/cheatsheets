use Mix.Config

config :my_app, MyApp.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  # long timeout to allow debugging in tests
  ownership_timeout: 20 * 60 * 1000

config :my_app, MyAppWeb.Endpoint,
  http: [port: 4001], # must be 4001 for Chromedriver (I think)
  server: true # required by Hound

# Print only warnings and errors during test
config :logger, level: :warn

# By default we use Chromedriver in headless mode.
# Comment out the :browser key to default to headful mode for debugging tests.
config :hound, driver: "chrome_driver", browser: "chrome_headless"

config :rollbax, enabled: false
