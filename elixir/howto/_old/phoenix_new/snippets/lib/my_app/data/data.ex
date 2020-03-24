defmodule MyApp.Data do
  import Ecto.Query
  alias MyApp.Repo
  alias MyApp.Data.{User, Nonce, LoginTry}

  #
  # Users
  #

  def get_user(id, filt \\ []), do: get_user_by(Keyword.merge([id: id], filt))
  def get_user!(id, filt \\ []), do: get_user_by!(Keyword.merge([id: id], filt))
  def get_user_by(filt), do: User |> User.apply_filters(filt) |> Repo.first()
  def get_user_by!(filt), do: User |> User.apply_filters(filt) |> Repo.first!()
  def get_users(filt \\ []), do: User |> User.apply_filters(filt) |> Repo.all()
  def count_users(filt \\ []), do: User |> User.apply_filters(filt) |> Repo.count()

  # New pattern: Each insert and update operation must provide a scope which is generally
  # :admin or :owner. :admin scope allows updates to all fields and should never be used
  # to pass user-defined params. :owner scope allows updates to only those fields which
  # should be updatable by the authed user who owns that record.
  def insert_user(params, s), do: user_changeset(%User{}, params, s) |> Repo.insert()
  def insert_user!(params, s), do: user_changeset(%User{}, params, s) |> Repo.insert!()
  def update_user(user, params, s), do: user_changeset(user, params, s) |> Repo.update()
  def update_user!(user, params, s), do: user_changeset(user, params, s) |> Repo.update!()
  def delete_user!(user), do: Repo.delete!(user)

  def user_changeset(user, params \\ %{}, scope) do
    case scope do
      :admin -> User.admin_changeset(user, params)
      :owner -> User.owner_changeset(user, params)
      :password_reset -> User.password_reset_changeset(user, params)
    end
  end

  def password_correct?(user_or_nil, password) do
    case Argon2.check_pass(user_or_nil, password) do
      {:ok, _user} -> true
      {:error, _msg} -> false
    end
  end

  #
  # Tokens
  #

  # Phoenix.Token gives us signed, salted, reversible, expirable tokens for free.
  # To protect from replay attacks, we embed a nonce id in each (otherwise stateless)
  # token. The nonce is validated at parsing time. Be sure to explicitly invalidate
  # the token when it's no longer needed!
  #
  # Usage:
  #   # Generate a single-use token:
  #   token = Data.new_token({:reset_password, user_id})
  #   # Later, parse and validate the token:
  #   {:ok, {:reset_password, user_id}} = Data.parse_token(token)
  #   # IMPORTANT: Destroy the token as soon as you no longer need it.
  #   Data.invalidate_token!(token)

  @endpoint MyAppWeb.Endpoint
  @salt "XAnZSi88BVsMtchJVa9"
  @one_day 86400

  def create_token!(data) do
    nonce = insert_nonce!()
    wrapped_data = %{data: data, nonce_id: nonce.id}
    Phoenix.Token.sign(@endpoint, @salt, wrapped_data)
  end

  def parse_token(token) do
    case Phoenix.Token.verify(@endpoint, @salt, token, max_age: @one_day) do
      {:ok, map} ->
        case valid_nonce?(map.nonce_id) do
          true -> {:ok, map.data}
          false -> {:error, "invalid nonce"}
        end

      {:error, msg} -> {:error, msg}
    end
  end

  def invalidate_token!(token) do
    {:ok, map} = Phoenix.Token.verify(@endpoint, @salt, token, max_age: :infinity)
    delete_nonce!(map.nonce_id)
    :ok
  end

  #
  # Nonces
  #

  def insert_nonce! do
    Nonce.admin_changeset(%Nonce{}, %{}) |> Repo.insert!()
  end

  def valid_nonce?(id) do
    Repo.get(Nonce, id) != nil
  end

  def delete_nonce!(id) do
    Repo.get!(Nonce, id) |> Repo.delete!()
  end

  #
  # Login tries
  #

  def insert_login_try!(email) do
    LoginTry.admin_changeset(%LoginTry{}, %{email: email}) |> Repo.insert!()
  end

  def count_recent_login_tries(email) do
    start_time = Timex.now() |> Timex.shift(minutes: -15)
    LoginTry
    |> where([t], t.email == ^email and t.inserted_at >= ^start_time)
    |> Repo.count()
  end

  def clear_login_tries(email) do
    LoginTry
    |> where([t], t.email == ^email)
    |> Repo.delete_all()
  end
end
