# Elixir & Phoenix

TODO: Move notes here once they're voluminous enough

## Ecto advanced query examples

Basic keyword-syntax query. Darin strongly recommends this syntax. It's no less composable and in many cases is much less verbose than the other syntax.

```
from t in "tracks",
  join: a in "albums", on: t.album_id == a.id,
  where: t.duration > 600,
  select: [t.id, t.title, a.title]
```

You can insert a nested set of records all at once. (Not yet clear how this works if you have a constraint error deep in, or if you have existing records that you want to associate with, etc.)

```
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
```

## Migrations & schemas for datetime columns

```
# User

## in the migration
add :will_invite_to_vote_on_date, :date
add :voting_invite_sent_at, :utc_datetime
add :voting_last_reminded_at, :utc_datetime

## in the schema
field :will_invite_to_vote_on_date, Timex.Ecto.Date # may be null
field :voting_invite_sent_at, Timex.Ecto.DateTime # UTC
field :voting_last_reminded_at, Timex.Ecto.DateTime # UTC

# Interview

## in the migration
add :will_invite_to_respond_on_date, :date
add :invite_sent_at, :utc_datetime

## in the schema
field :will_invite_to_respond_on_date, Timex.Ecto.Date # may be null
field :invite_sent_at, Timex.Ecto.DateTime # UTC

```
