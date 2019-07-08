# Plugs for deciding whether you're allowed to do a thing / view a page.
defmodule MyAppWeb.SentryPlugs do
  import Plug.Conn, only: [halt: 1]
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]
  alias MyAppWeb.Router.Helpers, as: Routes

  #
  # Plugs
  #

  def ensure_logged_in(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access that page.")
      |> redirect(to: Routes.page_path(conn, :index))
      |> halt()
    end
  end

  def ensure_not_logged_in(conn, _opts) do
    if conn.assigns.current_user do
      conn
      |> put_flash(:error, "You are already logged in.")
      |> redirect(to: Routes.page_path(conn, :index))
      |> halt()
    else
      conn
    end
  end
end
