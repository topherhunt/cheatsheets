defmodule Worldviews.Data do
  alias Worldviews.Data.User

  #
  # Users
  #

  def get_user(id, filt \\ []), do: get_user_by(Keyword.merge([id: id], filt))
  def get_user!(id, filt \\ []), do: get_user_by!(Keyword.merge([id: id], filt))
  def get_user_by(filt), do: User |> User.apply_filters(filt) |> Repo.first()
  def get_user_by!(filt), do: User |> User.apply_filters(filt) |> Repo.first!()
  def get_users(filt \\ []), do: User |> User.apply_filters(filt) |> Repo.all()
  def count_users(filt \\ []), do: User |> User.apply_filters(filt) |> Repo.count()

  def insert_user(params), do: new_user_changeset(params) |> Repo.insert()
  def insert_user!(params), do: new_user_changeset(params) |> Repo.insert!()
  def update_user(p, params), do: user_changeset(p, params) |> Repo.update()
  def update_user!(p, params), do: user_changeset(p, params) |> Repo.update!()
  def delete_user!(user), do: Repo.delete!(user)

  def new_user_changeset(params \\ %{}), do: User.changeset(%User{}, params)
  def user_changeset(user, params \\ %{}), do: User.changeset(user, params)

  #
  # Login tokens
  #

  def get_login_token(email) do
    # Instead of doing custom hash stuff, we use Phoenix.Token which gives us signed,
    # reversible, expirable tokens for free.
    Phoenix.Token.sign(WorldviewsWeb.Endpoint, "login token salt", email)
  end

  def verify_login_token(token) do
    Phoenix.Token.verify(WorldviewsWeb.Endpoint, "login token salt", token, max_age: 3600)
    # Will return {:ok, email} or {:error, _}
  end
end
