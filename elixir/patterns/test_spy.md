# Test spy

Elixir doesn't make it easy to mock / stub / assert that a particular method was called. There's a library, Mock, but all that does is replace the _entire module_ with an (optionally passthrough) mock module. If any logic in the underlying module indirectly calls a stubbed function, the function on the underlying module will be executed, rather than the stubbed version of it. So it's lame compared to Ruby's Mocha.

When testing complex logic (especially logic that invokes "service modules") I wanted my tests to be able to assert, "When I run this code, module ABC method XYZ is called with params MNO." After some fiddling I came up with a simple spy system: a supervised Agent that you can "log" events to, each event being a plain string describing the module, method, and params by convention, but of course it could be any string.

That agent was defined like this:

```rb
# Simple spy to help us inspect what logic gets called during tests.
# Spied tests CANNOT be async / parallel.
#
# Usage:
# - In the code you want to inspect, "log" the call:
#   MyApp.TestSpy.log_call({__MODULE__, :call, [athlete_ids, year]})
# - In your test example, clear the spied call history:
#   MyApp.TestSpy.clear()
# - Execute the exercised code as normal.
# - Check whether a particular call was made:
#   MyApp.TestSpy.called?({SomeModule, :some_method, [arg1, arg2]})
# - List all logged calls for debugging:
#   MyApp.TestSpy.all_calls |> Enum.map(& IO.puts inspect(&1))
#
defmodule MyApp.TestSpy do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def log(event) do
    if Mix.env == :test do
      Agent.update(__MODULE__, fn events -> [event | events] end)
    end
  end

  def logs do
    Agent.get(__MODULE__, fn events -> Enum.reverse(events) end)
  end

  def logs(string_or_regex) do
    Agent.get(__MODULE__, fn events -> Enum.filter(events, & &1 =~ string_or_regex) end)
  end

  def logged?(string_or_regex) do
    length(logs(string_or_regex)) > 0
  end

  def clear do
    Agent.update(__MODULE__, fn _events -> [] end)
  end
end
```

(^ It must live in lib/, rather than test/support/, because the module must be accessible in production code even though the messages aren't logged there.)

Then add it to the app's supervision tree like this:

```rb
# in application.ex
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      %{id: MyApp.Repo, start: {MyApp.Repo, :start_link, [[]]}, type: :supervisor},
      ...
      MyApp.TestSpy
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

In the code you want to spy on, you add a spy statement similarly to how you'd add a log statement for production behavior diagnostics:

```rb
  def call(user_id) do
    MyApp.TestSpy.log("#{__MODULE__}.call(id: #{user_id})")
    # Then run the logic
```

Then your test example will 1) clear the spy state, 2) run some logic, and then 3) make assertions against what events are now in the spy state:

```rb
  test "#some_function runs the detonator" do
    TestSpy.clear()

    SomeModule.some_function("abc")

    assert TestSpy.logged?("Detonator.call(id: abc)")
  end
```

Notes:

  - Add spy statements sparingly to avoid any performance concerns.

  - Spied tests cannot be async / parallel.

  - When spying on events with list inputs, you may want to explicitly sort and/or transform the list values so that you can deterministically assert against them.

  - After painstakingly developing this pattern to fill in some thorny test coverage, in the end I deleted it all and instead wrote the tests using factories and data stubbing helpers to generate all the needed state, then asserted that the outcome matched what would happen if the logic was being called correctly. In other words: This is a cool pattern, but in my most compelling use case so far, dumb fixture data ended up being a better solution.
