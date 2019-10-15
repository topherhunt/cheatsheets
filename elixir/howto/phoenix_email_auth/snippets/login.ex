# Print out a URL that I can click to "force login" as a registered user.
# See https://hexdocs.pm/mix/Mix.Task.html
# Usage: mix login hunt.topher@gmail.com
defmodule Mix.Tasks.Login do
  use Mix.Task
  alias RTL.Accounts
  alias RTLWeb.Router.Helpers, as: Routes

  @impl Mix.Task
  def run([email]) do
    Mix.Task.run("app.start") # Start the supervision tree (Repo etc.)

    if user = Accounts.get_user_by(email: email) do
      token = Accounts.get_login_token(user.email)
      url = Routes.auth_url(RTLWeb.Endpoint, :confirm, token: token)
      IO.puts "Login URL for #{email}: #{url}"
    else
      IO.puts "ERROR: No user matching email #{inspect(email)}"
    end
  end
end
