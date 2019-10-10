defmodule MyApp.Repo do
  use Ecto.Repo,
    otp_app: :calories,
    adapter: Ecto.Adapters.Postgres
  import Ecto.Query

  def count(query), do: query |> select([t], count(t.id)) |> one()
  def any?(query), do: count(query) >= 1
  def first(query), do: query |> limit(1) |> one()
  def first!(query), do: query |> limit(1) |> one!()

  def ensure_success(result) do
    case result do
      {:ok, object} -> object
      {:error, changeset} -> raise Ecto.InvalidChangesetError, changeset: changeset
    end
  end

  # Given a schema & batch size, returns a list of {min, max} windows for batching queries
  # Example:
  #   Repo.batch_ids(Athlete, 10_000)
  #   |> Enum.map(fn {min, max} -> run_batched_query(min, max) end)
  #   |> List.flatten()
  def batch_ids(schema_module, window_size) do
    max_id = from(t in schema_module, select: max(t.id)) |> one!()
    num_windows = trunc(max_id || 0 / window_size) + 1

    Enum.map(1..num_windows, fn n ->
      min = (n - 1) * window_size + 1
      max = n * window_size
      {min, max}
    end)
  end

  #
  # Describing changeset errors
  # (arguably doesn't belong in Repo)
  #

  # Assemble all this changeset's errors into a comma-separated summary.
  # e.g. "username can't be blank, password must be at most 20 characters"
  def describe_errors(changeset) do
    if length(changeset.errors) == 0, do: raise "This changeset has no errors to describe!"

    changeset
    |> inject_vars_into_error_messages()
    |> Enum.map(fn({field, errors}) -> "#{field} #{Enum.join(errors, " and ")}" end)
    |> Enum.join(", ")
    |> String.replace("(s)", "s")
  end

  defp inject_vars_into_error_messages(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn({msg, opts}) ->
      # e.g. input: {"must be at most %{count} chars", [count: 10, validation: ...]}
      #      output: "must be at most 3 chars"
      Enum.reduce(opts, msg, fn({key, value}, acc) ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
