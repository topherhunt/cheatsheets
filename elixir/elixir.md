## Installing on Mac OSX

Use Homebrew. Don't install the packages manually, it's super painful.

```
brew update
brew install erlang
brew install elixir
```

## Running Elixir code

- `iex`
- `iex -S mix` - shell in context of this project
- `mix run priv/repo/some_file.exs` - run an arbitrary script

## Mix commands

- `mix help`
- `mix new project_name`
- `mix test` - runs ExUnit tests
- `mix test test/file_name.exs:43`

## Misc.

- Use function `i/1` to get details about any value.
- Use `&&` and `||`, not `and` and `or`.
- `=` isn't assignment, it's the match operator.
- `^` is the pin operator. It forces matching against the current value rather than re-binding the variable. Often used in Ecto queries.
- `|>` is the pipe operator, my favorite thing ever.

## Strings, sigils, regexes

- Always use "double quotes" for strings. Never use 'single quotes'.
- See the binary representation of any string by concatenating a null byte to it:
  `"Hello" <> <<0>> => <<104, 101, 197, 130, 197, 0>>`
- Regex: `~r/foobar/i`
- List of strings: `~w(item1 item2 item3)`

## Dates & times

- Use Timex and Timex Ecto for datetime parsing. It's painful to do in vanilla Elixir.
- In the DB, store datetimes as `:utc_datetime`, not `:datetime`. There's also `:naive_datetime`.

## Lists, tuples

- Tuple: `{:ok, 5}`. For short, related groups of values. Not meant to be iterated through. Items can be accessed immediately.
- List: `[1, 2, 3]`. Has a head and a tail. Variable-length, may be long. Efficient to crawl sequentially, but calculating length or doing lookups is expensive. Adding to the beginning is efficient; adding to the middle or end is expensive.
- Concatenate two lists: `[1] ++ [2, 3] => [1, 2, 3]`
- Remove the items from the left-hand list: `[1, 2] -- [3, 1] => [2]`
- Check if a list (or range) contains a value: `3 in [1, 2, 4]`

##  Keyword lists, maps, structs

- A *keyword list* is a list of atom-keyed tuples: `[{:a, 1}, {:b, 2}]` - displayed as `[a: 1, b: 2]` for shorthand. Note that duplicate keys can be repeated. Like simple lists, this is useful for arbitrarily long key-value dicts, but keys/values are ordered and can only be accessed by iterating over the list.
- A *map* is a key-value data structure. Duplicate keys aren't allowed. Keys can be any kind of object, not just an atom. Keys are unordered; any key/value can be accessed immediately. Atom keys can be accessed like `map.key` or `map[:key]`; the former is preferable.
- Pattern-matching a map: `%{"user_id" => user_id, "user" => user_data} = params`
- Maps and keyword lists can be indefinitely nested. Use `put_in` and `update_in` to update.
- A *struct* is a named map with a defined set of allowed keys. Define it in a module:
  `defstruct(name: nil, age: nil)`.
- You can require fields to be present on a struct: `@enforce_keys [:field1]`

## Conditionals

If / unless / else statements work like in Ruby.
```
if condition do
  thing1()
else
  thing2()
end
```

Case statements check each pattern and evaluate the first match. Exception is raised if no matching clause is found. End with a `_` matcher to make an "else" clause.
```
case value do
  [minutes, seconds] ->
    (String.to_integer(minutes) * 60) + String.to_integer(seconds)
  [seconds] ->
    String.to_integer(seconds)
  _ ->
    raise "Don't know how to parse human time: #{input}"
end
```

Cond is similar to case, but with conditions rather than matchers. Frowned upon. No error is raised if no condition matches. End with a `true` condition to make an "else" clause.
```
cond do
  no_login_session?(conn) ->
    conn |> assign(:current_user, nil)
  session_expired?(conn) ->
    conn |> logout!
  true -> # No matching user found
    conn |> logout!
end
```

## Functions

- Anonymous function: `func = fn(a) -> a + 5 end`
- Default value for param: `def foo(bar \\ 3), do: ...`
- Passing functions to iterators etc.: `|> Enum.map(&String.split(&1, ","))`

## Modules

- `use` - invoke another module's __using__/1 function, which usually injects some code into the local module. A common extension point. You can pass it option keywords.
- `require` - ensure the module is compiled and available. Be careful of circular dependencies! Avoid using this. Lexically scoped, same as alias.
- `import` - imports some or all functions from another module, so they can be called as though local. Use the `:only` option to name exactly what functions are imported (improves clarity and reduces conflicts). Importing a module automatically requires it.
- `alias` - Makes a nested module available as though it were toplevel. eg. `alias Rumbl.Repo.Something` => available as `Something`. Lexically scoped to the module (or function) you call `alias` in.
- Alias multiple at once: `alias MyApp.{Foo, Bar, Baz}`

## Exceptions

- `raise "Some generic error"`
- `raise ArgumentError, message: "more specific error"`
- `defexception`
- `try / rescue / end` - usually you can avoid this. Don't use it for control flow.
- Don't use pattern-matching to assert `:ok` response code (like `{:ok, value} = foo(bar)`. This produces vague and unhelpful error messages. Instead, use a `case` statement, an "unwrapping" helper macro, or `with`. See http://michal.muskala.eu/2017/02/10/error-handling-in-elixir-libraries

## Processes

- Elixir processes are very lightweight. You can run 100K simultaneously.
- `spawn(function)` - returns the new process PID. Errors in the spawned process will NOT propagate to the parent.
- `spawn_link(function)` - errors in the spawned process WILL propagate to the parent.
- `Process.register(pid, :name)` lets you refer to the process by atom name instead of PID
- `self` - retrieve the PID of the current process
- `send` - add a message (usually a tuple) into a process's mailbox
- `receive` - a pattern-matched list of clauses that decides how to handle a message
- `flush()` - clears out this process's mailbox and prints all messages
- *Supervisors*: http://elixir-lang.org/getting-started/mix-otp/supervisor-and-application
- Explore the live supervision tree: `iex run :observer.start`. To ensure you can introspect and debug, make sure all processes you start are connected to a supervision tree.
- *Tasks, State, Agents, and GenServers* are abstractions built on processes that enable sturdy supervision trees, server-stored state, etc.
- An *Application* is a top-level supervisor for a tree of processes. Many dependencies start their own Applications (defined in `mix.exs`). When you run a `mix` command, it starts up all Applications. e.g. `Application.ensure_all_started(:myapp)`

## ETS

is an efficient, scalable data store on the Erlang VM. A useful, built-in alternative to Redis. But don't use this prematurely; often a registry process is enough for storing data.
