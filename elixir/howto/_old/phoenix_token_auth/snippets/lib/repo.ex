defmodule MyApp.Repo do
  use Ecto.Repo,
    otp_app: :my_app,
    adapter: Ecto.Adapters.Postgres
  import Ecto.Query

  def count(query), do: query |> select([t], count(t.id)) |> one()
  def any?(query), do: count(query) >= 1
  def first(query), do: query |> limit(1) |> one()
  def first!(query), do: query |> limit(1) |> one!()

  # Unwraps the result tuple and blows up if an error occurred.
  def ensure_success(result) do
    case result do
      {:ok, object} -> object
      {:error, changeset} -> raise Ecto.InvalidChangesetError, changeset: changeset
    end
  end

  # Use this to sanitize user-submitted filters against a whitelist so you
  # can include those filters in a query.
  # Returns a kw list of filter instructions like [email_contains: "blah"].
  # All keys are atoms. All values are (assumed to be) strings.
  def prepare_filters(filters, opts) do
    allowed = Keyword.fetch!(opts, :allowed)

    cleaned = Enum.reduce(allowed, [], fn field, kwlist ->
      value = filters[field]
      if value != nil && value != "" do
        Keyword.put(kwlist, String.to_atom(field), value)
      else
        kwlist
      end
    end)

    if cleaned != [] do
      cleaned
    else
      opts[:default] || []
    end
  end

  # Assemble all this changeset's errors into a list of human-readable message.
  # e.g. ["username can't be blank", "password must be at most 20 characters"]
  def describe_errors(changeset) do
    if length(changeset.errors) == 0, do: raise "This changeset has no errors to describe!"

    changeset
    |> inject_vars_into_error_messages()
    |> Enum.map(fn({field, errors}) -> "#{field} #{Enum.join(errors, " and ")}" end)
    |> Enum.map(& String.replace(&1, "(s)", "s"))
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
