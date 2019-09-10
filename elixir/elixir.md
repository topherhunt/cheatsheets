# Elixir: installing, syntax, tips, OTP


## Installing Elixir on OSX

The best way to install Elixir/Erlang and manage versions is using `asdf`.

  * Install asdf using instructions at https://asdf-vm.com/#/core-manage-asdf-vm
  * `asdf plugin-add erlang`
  * `asdf plugin-add elixir`
  * In your project folder, write a `.tool-versions` file specifying versions:
    ```
    # Tool versions for the asdf version manager
    elixir 1.8.1
    erlang 21.0.6
    ```
  * `asdf install` to install this Elixir & Erlang version
  * Now the `elixir`, `iex`, `mix`, and `erl` commands will use the versions specified.

For more asdf commands, see: https://asdf-vm.com/#/core-commands


## Misc.

- Use function `i/1` to get details about any value.
- Use `&&` and `||`, not `and` and `or`.
- `^` is the pin operator. It forces matching against the current value rather than re-binding the variable. Often used in Ecto queries.
- `|>` is the pipe operator, my favorite thing ever.


## Reading & writing files

Write a file:

```rb
File.write!("tmp/filename.txt", contents)
```

Open a file and process each line:

```rb
# Note that Enum.map eager-loads all streamed data. This will use lots of memory for
# large files.
File.stream!("./input.txt")
|> Enum.map(fn(line) ->
  cleaned = String.trim(line)
  op = String.at(cleaned, 0)
  {amount, _rem} = Integer.parse(String.slice(cleaned, 1..-1))
  {op, amount}
end)
```

Open a file and process each line, using Streams to minimize memory usage:

```rb
File.stream!(filename, encoding: :utf8)
|> Stream.map(fn(line) -> Jason.decode!(line) end)
|> Stream.filter(& has_lat_lng_data?(&1))
|> Enum.to_list()
# Calling Enum will eager-load the streamed data. All items that survived the Stream.filter
# will be loaded into memory at once now.
```


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


## Umbrella apps

  * If you're just trying to break a monolith into multiple self-contained apps but still keep them in one big git repo, do NOT use an umbrella. Simply put each app in a subfolder. They can reference each other as deps using the `:path` option.

  * Good use cases for an umbrella:
    - you want to run `mix test` to run all your sub-apps test suites in one go
    - you want all sub-apps to all share the same config and same dependencies

  * More info: https://elixir-lang.org/getting-started/mix-otp/dependencies-and-umbrella-projects.html


## Architecture & structure best practices

  * Structural modules (eg. genservers, LVs, other OTP-related modules, Phx controllers) should not contain domain / business logic.


## Performance & benchmarking

Here's an example of using Benchee to test whether duplicate Ecto preloads "share" the same in-memory object or not. If preloads are shared, I'd expect the `plus_athlete` case to have substantially higher memory usage than the `plus_event` case.

```rb
entry_ids = from(en in Entry, where: en.event_id == ^4973, select: en.id) |> Repo.all()

Benchee.run(
  %{
    "just_entry" => fn -> from(en in Entry, where: en.id in ^entry_ids) |> Repo.all() end,
    "plus_athlete" => fn -> from(en in Entry, where: en.id in ^entry_ids, preload: :athlete) |> Repo.all() end,
    "plus_event" => fn -> from(en in Entry, where: en.id in ^entry_ids, preload: :event) |> Repo.all() end,
    "plus_both" => fn -> from(en in Entry, where: en.id in ^entry_ids, preload: [:athlete, :event]) |> Repo.all() end
  },
  time: 10,
  memory_time: 10
)
```

The output suggests that preloading each Entry's Event (all Entries belong to the same Event) uses substantially less memory than preloading each Entry's Athlete (each Entry belongs to a different Athlete). Seems like confirmation of my hope: Ecto preloaded associations reuse the same in-memory object where possible, saving duplicate memory.

```
Memory usage statistics:

Name                 average  deviation         median         99th %
just_entry           7.07 MB     ±0.03%        7.07 MB        7.08 MB
plus_event           7.77 MB     ±0.02%        7.77 MB        7.78 MB
plus_athlete        19.78 MB     ±0.02%       19.78 MB       19.79 MB
plus_both            8.03 MB     ±0.02%        8.03 MB        8.03 MB

Comparison:
just_entry           7.07 MB
plus_event           7.77 MB - 1.10x memory usage +0.70 MB
plus_athlete        19.78 MB - 2.80x memory usage +12.71 MB
plus_both            8.03 MB - 1.14x memory usage +0.96 MB
```

Note: preloading _both_ the Entry's athlete and event appears to use far less memory than preloading the athlete alone. This is counterintuitive, and suggests that Ecto's preloading logic is more nuanced than it looks.
