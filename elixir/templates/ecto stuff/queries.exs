# See `Ecto.Repo` docs for full list of Repo read/write functions
# See `Ecto.Query` and `Ecto.Query.API` for full API of querying functions
# Note that any variable values must be pinned using `^`

# A simple query (macro syntax)

first_user = User
  |> select([u], count(u.id))
  |> where([u], ilike(u.username, ^"%substring%"))
  |> where(fragment("lower(username) = ?", ^search_term))
  |> Repo.one

# A simple query (keyword syntax, avoid this)

from t in "tracks",
  join: a in "albums", on: t.album_id == a.id,
  where: t.duration > 600,
  select: [t.id, t.title, a.title]

# A nested insertion

Repo.insert!(%Artist{
  name: "Michael Jackson",
  albums: [
    %Album{
      title: "Abbey Road",
      tracks: [
        %Track{ title: "Thriller" },
        %Track{ title: "Bad" },
        %Track{ title: "Something Else" }
      ]
    }
  ]
})
