defmodule MyAppWeb.AuthPlugs do
  require Logger
  import Plug.Conn,
    only: [
      assign: 3,
      get_session: 2,
      put_session: 3,
      configure_session: 2
    ]
  alias MyApp.Data

  #
  # Plugs
  #

  # Assign current_user to the conn, if a user is logged in
  def load_current_user(conn, _opts) do
    cond do
      # If a user is already loaded, nothing to do
      current_user_assigned?(conn) -> conn
      # If no user is logged in, explicitly set current_user to nil
      no_login_session?(conn) -> assign(conn, :current_user, nil)
      # If the session is expired, log me out (must be before load_user_from_session!)
      session_expired?(conn) -> logout!(conn)
      # If we can find the user with this id, assign them
      user = load_user_from_session(conn) -> set_assigned_user(conn, user)
      # If no user was found by that id, the session is invalid. Log me out.
      true -> logout!(conn)
    end
  end

  #
  # External helpers
  #

  # Start a login session for an (already authenticated) user
  def login!(conn, user) do
    conn
    |> assign(:current_user, user)
    |> put_session(:user_id, user.id)
    |> put_session(:expires_at, new_expiration_string())
    |> configure_session(renew: true)
  end

  # To log out, we just nuke the whole (cookie-stored) session.
  def logout!(conn) do
    conn
    |> assign(:current_user, nil)
    |> put_session(:user_id, nil)
    |> configure_session(drop: true)
    # But we don't halt the conn. Later plugs can decide what response to give.
  end

  #
  # Internal helpers
  #

  defp current_user_assigned?(conn) do
    conn.assigns[:current_user] != nil
  end

  defp no_login_session?(conn) do
    get_session(conn, :user_id) == nil
  end

  defp load_user_from_session(conn) do
    # To support "Log out of all sessions", we'd look up the user here by both id and a
    # session_token which we can scramble to destroy all login sessions.
    user_id = get_session(conn, :user_id)
    Data.get_user_by(id: user_id)
  end

  defp set_assigned_user(conn, user) do
    if user.last_visit_date != Date.utc_today() do
      Data.update_user!(user, %{last_visit_date: Date.utc_today()}, :admin)
    end

    conn
    |> put_session(:expires_at, new_expiration_string()) # Renew the session lifetime
    |> assign(:current_user, user)
  end

  #
  # Expiry helpers
  #

  defp session_expired?(conn) do
    expires_at = get_session(conn, :expires_at)
    expires_at == nil || is_past?(parse_time(expires_at))
  end

  defp is_past?(time), do: Timex.before?(time, Timex.now())

  defp parse_time(string), do: Timex.parse!(string, "{ISO:Extended}")

  defp new_expiration_string do
    Timex.now() |> Timex.shift(days: +1) |> Timex.format!("{ISO:Extended}")
  end
end
