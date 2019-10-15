# Generic context for this tiny schema
defmodule MyApp.Data do
  alias MyApp.Repo
  alias MyApp.Data.User

  #
  # Users
  #

  def get_user(id, filt \\ []), do: query_users([{:id, id} | filt]) |> Repo.one()
  def get_user!(id, filt \\ []), do: query_users([{:id, id} | filt]) |> Repo.one!()
  def get_user_by(filt), do: query_users(filt) |> Repo.first()
  def get_user_by!(filt), do: query_users(filt) |> Repo.first!()
  def get_users(filt \\ []), do: query_users(filt) |> Repo.all()
  def count_users(filt \\ []), do: query_users(filt) |> Repo.count()
  def query_users(filt), do: User |> User.filter(filt)

  def insert_user(params), do: new_user_changeset(params) |> Repo.insert()
  def insert_user!(params), do: new_user_changeset(params) |> Repo.insert!()
  def update_user(p, params), do: user_changeset(p, params) |> Repo.update()
  def update_user!(p, params), do: user_changeset(p, params) |> Repo.update!()
  def delete_user!(user), do: Repo.delete!(user)

  def new_user_changeset(params \\ %{}), do: User.changeset(%User{}, params)
  def user_changeset(user, params \\ %{}), do: User.changeset(user, params)

  # Resetting the session_token voids all currently-active login sessions, so the user
  # can be sure that they aren't still logged in on some forgotten device.
  def reset_user_sessions(user), do: update_user!(user, %{session_token: ""})

  #
  # Login tokens
  #

  def get_login_token(email) do
    # Phoenix.Token gives us signed, salted, reversible, expirable tokens for free.
    Phoenix.Token.sign(MyAppWeb.Endpoint, "login token salt", email)
  end

  def verify_login_token(token) do
    Phoenix.Token.verify(MyAppWeb.Endpoint, "login token salt", token, max_age: 3600)
    # Will return {:ok, email} or {:error, _}
  end
end
