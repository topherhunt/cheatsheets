defmodule Worldviews.Emails do
  import Bamboo.Email
  use Bamboo.Phoenix, view: WorldviewsWeb.EmailsView
  alias WorldviewsWeb.Router.Helpers, as: Routes

  def confirm_address(email) do
    token = Worldviews.Data.get_login_token(email)
    url = Routes.auth_url(WorldviewsWeb.Endpoint, :confirm, token: token)

    new_email()
    |> to(email)
    |> from("worldview-journeys-noreply@topherhunt.com")
    |> subject("[Worldview Journeys] Your special log-in link")
    |> put_html_layout({WorldviewsWeb.LayoutView, "email.html"})
    |> render("confirm_address.html", url: url)
  end
end
