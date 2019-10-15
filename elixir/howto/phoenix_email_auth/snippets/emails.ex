defmodule Worldviews.Emails do
  use Bamboo.Phoenix, view: WorldviewsWeb.EmailsView
  import Bamboo.Email
  alias WorldviewsWeb.Router.Helpers, as: Routes
  require Logger

  def confirm_address(email) do
    token = Worldviews.Data.get_login_token(email)
    url = Routes.auth_url(WorldviewsWeb.Endpoint, :confirm, token: token)

    if Mix.env == :dev, do: Logger.info "Login link for #{email}: #{url}"

    new_email()
    |> to(email)
    |> from("worldview-journeys-noreply@topherhunt.com")
    |> subject("[Worldview Journeys] Your special log-in link")
    |> put_html_layout({WorldviewsWeb.LayoutView, "email.html"})
    |> render("confirm_address.html", url: url)
  end
end
