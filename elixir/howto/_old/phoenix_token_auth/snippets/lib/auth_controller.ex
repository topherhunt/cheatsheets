defmodule MyAppWeb.Api.AuthController do
  use MyAppWeb, :controller
  alias MyApp.Accounts

  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        token = Accounts.new_token_for_user(user)
        json(conn, %{ok: true, token: token})

      {:error, reason} ->
        conn
        |> put_status(401)
        |> json(%{ok: false, reason: login_failure_message(reason)})
    end
  end

  def register(conn, %{"user" => user_params}) do
    case Accounts.insert_user(user_params) do
      {:ok, user} ->
        token = Accounts.new_token_for_user(user)
        json(conn, %{ok: true, token: token})

      {:error, changeset} ->
        conn
        |> put_status(422)
        |> json(%{ok: false, reason: registration_failure_message(changeset)})
    end
  end

  #
  # Helpers
  #

  defp login_failure_message(reason) do
    case reason do
      :invalid_credentials -> "Your username or password is incorrect. Please try again."
    end
  end

  defp registration_failure_message(changeset) do
    errors = Enum.map(changeset.errors, fn({field, {msg, _}}) -> "#{field} #{msg}" end)
    "Registration failed due to the following error(s): #{Enum.join(errors, ", ")}"
  end
end
