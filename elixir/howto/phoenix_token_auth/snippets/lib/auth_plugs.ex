defmodule MyAppWeb.AuthPlugs do
  import Plug.Conn, only: [assign: 3, halt: 1, put_status: 2]
  import Phoenix.Controller
  alias MyApp.Accounts

  # Assign current_user to the conn, if a user is logged in
  def load_user_from_token(conn, _opts) do
    with :ok <- ensure_no_user_assigned(conn),
         {:ok, token} <- get_token(conn),
         {:ok, user_id} <- parse_token(token),
         {:ok, user} <- get_user(user_id) do
      assign(conn, :current_user, user)
    else
      {:error, :user_already_assigned} -> conn
      {:error, :no_auth_token} -> assign(conn, :current_user, nil)
      {:error, :token_invalid} -> halt_with_invalid_token_error(conn)
      {:error, :user_not_found} -> halt_with_invalid_token_error(conn)
    end
  end

  def require_user(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_status(401)
      |> json(%{"error" => "user_required"})
      |> halt()
    end
  end

  #
  # Helpers
  #

  defp ensure_no_user_assigned(conn) do
    if conn.assigns[:current_user] do
      {:error, :user_already_assigned}
    else
      :ok
    end
  end

  defp get_token(conn) do
    # If the token is provided in the request header (the only option for now), we expect
    # it to use the standard OAuth "Authorization: Bearer MY_TOKEN" format.
    header = Enum.find(conn.req_headers, fn({k, _v}) -> k == "authorization" end)

    if header do
      {"authorization", "Bearer "<>token} = header
      {:ok, token}
    else
      {:error, :no_auth_token}
    end
  end

  defp parse_token(token) do
    case Accounts.verify_token_and_get_user_id(token) do
      {:ok, user_id} -> {:ok, user_id}
      {:error, _reason} -> {:error, :token_invalid}
    end
  end

  defp get_user(user_id) do
    if user = Accounts.get_user(user_id) do
      {:ok, user}
    else
      {:error, :user_not_found}
    end
  end

  defp halt_with_invalid_token_error(conn) do
    conn
    |> put_status(401)
    |> json(%{"error" => "invalid_token"})
    |> halt()
  end

end
