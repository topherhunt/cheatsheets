defmodule MyAppWeb.SentryPlugs do
  import Plug.Conn, only: [halt: 1]
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]
  import MyAppWeb.Gettext
  alias MyAppWeb.Router.Helpers, as: Routes

  def must_be_logged_in(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_flash(:error, gettext("Please log in first."))
      |> redirect(to: Routes.auth_path(conn, :login))
      |> halt()
    end
  end
end
