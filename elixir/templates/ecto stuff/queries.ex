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

#
# Run a query in batches of 1000 ids:
#

# In Repo, define a batch_ids function to generate id windows:
defmodule MyApp.Repo do
  # ...

  # Given a schema & batch size, returns a list of {min, max} windows for batching queries
  def batch_ids(schema_module, window_size) do
    max_id = from(t in schema_module, select: max(t.id)) |> one!()
    num_windows = trunc(max_id / window_size) + 1

    Enum.map(1..num_windows, fn n ->
      min = (n - 1) * window_size + 1
      max = n * window_size
      {min, max}
    end)
  end
end

# Now your target code should map over those windows and run the relevant query once
# for each batch. Make sure that the queries are in fact isolated so batching won't
# impact your results!
def all_results do
  Repo.batch_ids(User, 10_000)
  |> Enum.map(fn {min, max} -> results_for_ids(min, max) end)
  |> List.flatten()
end

def results_for_ids(min_id, max_id) do
  from(u in User, where: u.id >= ^min_id and u.id <= ^max_id) |> Repo.all()
end

# Poor-man's batching also works if you have a specific list of ids:
# (Careful - at 100K+ ids this will allocate huge amounts of memory! Use Benchee to test.)
specific_user_ids
|> Enum.chunk_every(100)
|> Enum.map(fn ids -> {Enum.min(ids), Enum.max(ids)} end)
|> Enum.map(fn {min, max} -> results_for_ids(min, max) end)

#
# Fully-manual query, with injections (unsafe):
#

"""
SELECT entries.athlete_id, cevent_categories.name, count(*)
  FROM entries INNER JOIN cevents
                       ON cevents.id = entries.event_id
               INNER JOIN cevent_categories
                       ON cevent_categories.id = cevents.event_category_id
 WHERE cevents.starts_at between $2 AND $3
   AND (entries.completion_time = 0 OR entries.completion_time IS NULL)
   AND entries.athlete_id in (SELECT athlete_id FROM athletes)
 GROUP BY entries.athlete_id, cevent_categories.name
 ORDER BY entries.athlete_id
"""
|> Repo.query!([event.id, sdate, edate])
