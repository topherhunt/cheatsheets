defmodule Jwt.Accounts do
  import Ecto.Query, warn: false
  alias Jwt.Repo
  alias Jwt.Accounts.User

  #
  # Users
  #

  def get_user(id, filters \\ []) do
    User |> User.apply_filters([{:id, id} | filters]) |> Repo.first()
  end

  def get_user!(id, filters \\ []) do
    User |> User.apply_filters([{:id, id} | filters]) |> Repo.first!()
  end

  def get_user_by(filters \\ []) do
    User |> User.apply_filters(filters) |> Repo.first()
  end

  def list_users(filters) do
    User |> User.apply_filters(filters) |> Repo.all()
  end

  def count_users(filters \\ []) do
    User |> User.apply_filters(filters) |> Repo.count()
  end

  def insert_user(attrs \\ %{}) do
    %User{} |> User.changeset(attrs) |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user |> User.changeset(attrs) |> Repo.update()
  end

  def insert_user!(attrs), do: insert_user(attrs) |> Repo.ensure_success()
  def update_user!(user, attrs), do: update_user(user, attrs) |> Repo.ensure_success()

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  # User changeset for use in forms etc.
  def change_user(%User{} = user \\ %User{}) do
    User.changeset(user, %{})
  end

  #
  # Authentication & token helpers
  #

  # Given login credentials, returns the matching user if the creds are correct.
  def authenticate_user(email, password) do
    user = get_user_by(email: email)

    if user do
      if Bcrypt.verify_pass(password, user.password_hash) do
        {:ok, user}
      else
        {:error, :invalid_credentials}
      end
    else
      Comeonin.Bcrypt.dummy_checkpw()
      {:error, :invalid_credentials}
    end
  end

  @token_salt "hard-coded salt for user auth tokens"

  def new_token_for_user(user) do
    signed_at = System.system_time(:second)
    # Currently we don't expire tokens. But if we decide to expire them in the future,
    # encoding signed_at will give us a pathway for detecting old tokens so we can issue
    # a new one as relevant.
    data = %{user_id: user.id, signed_at: signed_at}
    Phoenix.Token.sign(JwtWeb.Endpoint, @token_salt, data, signed_at: signed_at)
  end

  def verify_token_and_get_user_id(token) do
    # TODO: Currently tokens have infinite lifetime. For safety we should expire them
    # after a day or so, and implement a way for the consumer to exchange for a fresh one.
    case Phoenix.Token.verify(JwtWeb.Endpoint, @token_salt, token, max_age: :infinity) do
      {:ok, %{user_id: user_id}} -> {:ok, user_id}
      {:error, reason} -> {:error, reason}
    end
  end
end
