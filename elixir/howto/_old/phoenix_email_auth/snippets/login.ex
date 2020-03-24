# Print out a URL that I can click to "force login" as a registered user.
# See https://hexdocs.pm/mix/Mix.Task.html
# Usage: mix login hunt.topher@gmail.com
defmodule Mix.Tasks.Login do
  use Mix.Task
  alias MyApp.Data
  alias MyAppWeb.Router.Helpers, as: Routes

  @impl Mix.Task
  def run([email]) do
    Mix.Task.run("app.start") # Start the supervision tree (Repo etc.)

    if user = Data.get_user_by(email: email) do
      token = Data.new_login_token(user.email)
      url = Routes.auth_url(MyAppWeb.Endpoint, :confirm, token: token)
      IO.puts "Login URL for #{email}: #{url}"
    else
      IO.puts "ERROR: No user matching email #{inspect(email)}"
    end
  end
end
