defmodule MyAppWeb.IntegrationCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Phoenix.ConnTest
      use Hound.Helpers # See https://github.com/HashNuke/hound for usage info
      import MyApp.EmailHelpers
      import MyAppWeb.IntegrationHelpers
      alias MyAppWeb.Router.Helpers, as: Routes
      alias MyApp.Factory

      @endpoint MyAppWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(MyApp.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(MyApp.Repo, {:shared, self()})
    end

    # MyApp.DataHelpers.empty_database()
    ensure_driver_running()
    System.put_env("SUPERADMIN_EMAILS", "superadmin@example.com")
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def ensure_driver_running do
    {processes, _code} = System.cmd("ps", [])

    unless processes =~ "chromedriver" do
      raise "Integration tests require ChromeDriver. Run `chromedriver` first."
    end
  end
end
