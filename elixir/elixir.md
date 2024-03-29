# Elixir: installing, syntax, tips, OTP


## References

  * [Elixir intro guide](https://elixir-lang.org/getting-started/introduction.html)
    (Highly recommend the OTP & metaprogramming tutorials too)
  * [Elixir official docs](https://hexdocs.pm/elixir/Kernel.html)
  * [Talk: Intro to Phoenix](https://www.youtube.com/watch?v=OxhTQdcieQE)
  * [Phoenix official docs](https://hexdocs.pm/phoenix/overview.html)
  * [Fun tutorial on "minimum viable Phoenix"](http://www.petecorey.com/blog/2019/05/20/minimum-viable-phoenix/)


## Best practices

  * Multi-signature functions should be rare (unless you're following a specific DSL eg. in genservers).
  * Only use a pipe when there's no risk of confusion about what type of value is being passed, and preferably if it's the same kind of value all the way down the pipe (e.g. a list undergoing various minor transformations).
  * Raise errors as early as possible.
  * Layers of indirection should have comments that identify them and justify them.


## Warts

There's a couple really ugly things about Elixir:

  * Counterintuitive Erlang term comparison. If you try to compare two dates, it will compare based on structure rather than semantics.
  * Working with decimals (eg. adding or comparing them) is verbose & painful.
  * Lists of integers often get "interpreted" as a charlist when inspected. There's no straightforward way to configure `inspect` to print integer lists as lists rather than charlists. (outside of iex)
  * It's hard to detect a misspelled module eg. in config. Because module names are just atoms, Elixir isn't very proactive about blowing up if you misspell your module. This can lead to silent failures / configured components getting dropped.
  * Map keys are alphasorted, meaning it's hard to render a json api response with object keys in "semantic ordering". I know this matches the json object spec, but it's inconvenient.


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

`mix deps.clean --unlock --unused` - clean out no-longer-used packages from the lockfile.


`and` and `or` require strict booleans. `&&` and `||` allow any truthy / falsey values.

Reverse a map: `Map.new(map, fn {k, v} -> {v, k} end)`

Inspect all bound variables in this context: `IO.inspect binding()`

Random number: `:rand.uniform(50)` (from Erlang)


## Dates & times

  * Elixir's Date library is pretty solid, but its support for DateTime parsing & manipulation is very limited. Use Timex for the latter.

  * **BE CAREFUL:** Never compare dates (or datetimes) using > / < / >= / <=. Use `Date.diff(date, other)` or `date in Date.range(sdate, edate)` instead.

  * Sort a list of datetimes:
    `datetimes |> Enum.sort(& DateTime.compare(&1, &2) != :gt)` (if timezoned)
    `datetimes |> Enum.sort(& NaiveDateTime.compare(&1, &2) != :gt)` (if naive)
    `datetimes |> Enum.sort(& Timex.diff(&1, &2) < 0)` (using Timex)


## Reading & writing files

Write a file:

```rb
# This overwrites any prior content
File.write!("tmp/filename.txt", contents)

# This preserves any prior content
File.write!("topher.txt", new_contents, [:append])
```

Open a file, loading its full contents into a string:

```rb
contents = File.read!("./input.txt")
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

Parse a csv string (using the :csv package):

```rb
"a,b,c\n1,2,3\n4,5,6"
|> String.split("\n")
|> CSV.decode!()
|> Enum.to_list()
```


## Metaprogramming

  * How `use` works: https://brooklinmyers.medium.com/using-use-usefully-in-elixir-and-phoenix-b59a5ea08ad2
  * Tips on how to use `defimpl` to implement a protocol for a module, so for example you can teach PID and other object types how they should be stringified: https://www.devbrett.com/2018/08/implement-string-protocol-elixir-pid.html

```rb
# /lib/my_app/utils/pid.ex
defimpl String.Chars, for: PID do
  def to_string(pid) do
    info = Process.info(pid)
    name = info[:registered_name]
    "#{name}-#{inspect(pid)}"
  end
end
```


## OTP

Start the Erlang OTP observer UI:

    :observer.start()

Run code in a linked background process (eg. to start a lightweight job from the controller):
(If the job raises an exception, the parent process will crash.)

    Task.start_link(fn ->
      # run stuff here
    end)

Tips on testing multi-process Elixir code: https://samuelmullen.com/articles/elixir-processes-testing/


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


## Memory usage in strings & atoms

  * Each atom used reserves around 110-140 bytes of memory in the Erlang VM, permanently. By default, Erlang sets a ceiling of ~ 1 million atoms, and crashes if you exceed that.

  * Re-using the same atom is nearly free memory-wise. So in a long list of atom-keyed maps, the repeated atoms don't create much memory pressure, regardless of their length.

  * But a long list of STRING-keyed maps will weigh a lot, because each instance of the string is stored separately in memory even if the strings are equivalent.


## Performance benchmarking

  * Check total memory in use by the Erlang VM:
    `memory_used_mb = Float.round(:erlang.memory[:total] / 1_000_000.0, 3)`

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
