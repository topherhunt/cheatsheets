# Elixir: Syntax, structure, components, tips


## Installing Elixir on OSX

Use Homebrew. Don't install the packages manually, it's super painful.

First install Erlang:

* `brew update`
* `brew install erlang`

Use Kiex to install Elixir and manage installed versions.

* Install Kiex: https://github.com/taylor/kiex
* `kiex list` - list installed Elixirs
* `kiex install 1.3.4` - install a specific Elixir version
* `kiex default 1.3.4` - set the default Elixir version (need to restart session)

Then ensure Hex PM is installed: `mix local.hex`


## Misc.

- Use function `i/1` to get details about any value.
- Use `&&` and `||`, not `and` and `or`.
- `^` is the pin operator. It forces matching against the current value rather than re-binding the variable. Often used in Ecto queries.
- `|>` is the pipe operator, my favorite thing ever.


## Dates & times

- In the DB, store datetimes as `:utc_datetime`, not `:datetime`. There's also `:naive_datetime`.


## File reading & writing

    def load_and_parse_operations_list do
      File.stream!("./input.txt")
      |> Enum.map(fn(line) ->
        cleaned = String.trim(line)
        op = String.at(cleaned, 0)
        {amount, _rem} = Integer.parse(String.slice(cleaned, 1..-1))
        {op, amount}
      end)
    end


## OTP

  * Start the Erlang OTP observer UI: `:observer.start()`


## ETS

Creating an ETS in-memory table is easy:

```
table = :ets.new(:buckets_registry, [:set, :protected])
:ets.insert(table, {"foo", self()})
:ets.lookup(table, "foo")
```

You can also create a table that's referenced by atom name instead of by ref:

```
table = :ets.new(:buckets_registry, [:named_table])
:ets.insert(:buckets_registry, {"foo", self()})
:ets.lookup(:buckets_registry, "foo")
```

ETS table options include:

  * `:set` (default) - this table will be a Set. Keys cannot be duplicated.
  * `:protected` (default) - any process can read from this table, but only the creator process can write to it.
  * `:named_table`

