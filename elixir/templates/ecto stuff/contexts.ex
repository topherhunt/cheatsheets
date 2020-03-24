# Generic context for this tiny schema
defmodule MyApp.Data do
  alias MyApp.Data.User

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
  # TODO: Will this cascade deletion of all dependent resources?
  def delete_user!(user), do: Repo.delete!(user)

  def new_user_changeset(params \\ %{}), do: User.changeset(%User{}, params)
  def user_changeset(user, params \\ %{}), do: User.changeset(user, params)
end
