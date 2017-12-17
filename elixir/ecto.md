## Mix commands

- `mix ecto.create`
- `mix ecto.gen.migration create_user`
- `mix ecto.migrate`
- `mix ecto.rollback`
- `mix ecto.drop`
- `mix ecto.reset` - drops, creates, migrates, and seeds
- `MIX_ENV=test mix ecto.reset_test` - no seeds
- `mix run priv/repo/seeds.exs`

## Models (Schemas)

- Declare a field as `virtual: true` so it won't be persisted.
- Declare a field as type `{:array, :string}` to make it a List of that value type. Useful with virtual attrs.
- Lifecycle hooks: You can add `:on_delete` behavior to the db layer (during migration) or to the schema's association (less performant)
- Best practice: Mention all indexes and constraints as comments in the `schema` block, since Phoenix doesn't have a `schema.rb` equivalent.

## Changesets

- `changeset = Rumbl.Video.changeset(video, %{field: "updated_value"})`
- `changeset.errors` will be populated if the changeset failed validations
- Params to a changeset should default to the atom `:empty` if no form was submitted.
- Warning: If you misspell a field in a validation macro, *it will silently skip that field*. Ensure test coverage of all validations.

Validations available:
- `validate_acceptance`
- `validate_change` - eg. to require user to change their password
- `validate_confirmation`  - eg. password must match confirmation
- `validate_inclusion`
- `validate_format`
- `validate_exclusion`
- `validate_length` (warning: this does not validate presence!)
- `validate_number`
- `validate_required([:field1, :field2])`
- `validate_subset`

- Constraints: catch db-level constraint violations and convert them into friendly validation errors. These do nothing unless you've actually added the db constraint.
  * `unique_constraint(:username)`
  * `assoc_constraint(:category)` - verifies that the associated record exists (guesses the FK based on assoc name)
  * There's other db-level constraints available. See https://hexdocs.pm/ecto/Ecto.Changeset

## Insert, update, delete, fetch

```
Repo.get(module, id) - nil if no result
Repo.get!(module, id) - raises exception if no result
Repo.get_by(module, [keywords]) - nil if no result
Repo.get_by!(module, [kwds]) - exception if no result
Repo.all(queryable)
Repo.one(queryable) - exception unless exactly 1 result
Repo.insert(changeset_or_model) - :error if failed
Repo.insert!(changeset_or_model) - exception if failed
Repo.update(changeset)
Repo.update!(changeset)
Repo.delete(result) - :error response if failed
Repo.delete!(result) - raises exception if failed
```

## Queries

- https://hexdocs.pm/ecto/Ecto.Query.html
- Ecto queries come in 2 formats: keywords or macros. I strongly prefer macros.
- Use fragments to add arbitrary SQL: `|> where(fragment("lower(username) = ?", ^some_var))`

```
User
  |> select([u], count(u.id))
  |> where([u], ilike(u.username, ^"%substring%"))
  |> Repo.one
```

## Associations

- During a query, pipe through `|> Ecto.preload(:videos)` to preload an association
- `user = Repo.preload(user, :videos)` - returns the `user` with `user.videos` populated
- `videos = Ecto.assoc(user, :videos)` - returns the associations as a list
- Nested associations: `Ecto.assoc(post, [:comments, :author]`
