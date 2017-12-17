## Commands

- `mix test` - runs test suite (auto migrates db first)
- `mix test --trace`
- `mix test path/to/folder/or/file.exs`
- `mix test path/to/folder/or/file.exs:31` - run just a single test

## Organizing tests

- Use TDD to drive out all new interfaces and non-trivial features.
- Test what the code does, not how it does it.
- Tests should be highly readable, and look like documentation of the requirements.
- Use helper methods / modules liberally to keep tests brief and readable.
- `use ExUnit.case, async: true` - most tests can be run concurrently even if they touch the DB thanks to Ecto 2.0's sandbox mode. If a test can't be run async, set `async: false`.
- ExUnit has no concept of contexts, so you only get one `setup` block per file. Use helper methods instead.

My test suite should always include:
- Controller tests for every action and path. The standard tests:
  * all actions require logged-in user
  * actions that require specific user, fail if different user
  * #index lists records I'm authorized to see
  * #show displays details
  * #new displays the new form
  * #create creates the record and redirects if valid
  * #create makes no changes and shows errors if invalid
  * #edit displays the edit form
  * #update updates the record and redirects if valid
  * #update makes no changes and shows errors if invalid
  * #delete deletes the record and redirects
  * custom actions or custom logic: cover expected behavior of each possible branch
- Unit tests for every schema (validations and non-trivial helper functions)
- Top-level unit tests for every logic module
- Unit tests for every view helper function
- Judicious integration tests covering the essential feature set. Pretend the integration test suite is a 5-minute client demo meeting.

### Controller tests

- `bypass_through/2` - sets up `@conn` so you don't have to stub out each plug
- `assert_error_sent(404, fn -> ...)`
- `assert html_response(conn, 200) =~ "Matching text"`
- `assert json_response/2` - similar to above
- `assert conn.resp_body =~ "substring"`
- `assert conn.status == 204`

## Debugging

- `IO.puts("arbitrary string")`
- `IO.inspect(value)`
- Run IEx.pry:
  * In `config/test.exs`, set `:ownership_timeout` to a large value so db connections don't time out while prying
  * Add `require IEx` to the target file
  * Insert `IEx.pry` at the target line
  * Run the tests in iex: `iex -S mix test --trace`
- You can inspect any Hex dependency code in `deps/`. You can even alter the code of a dependency, run `mix deps.compile`, then restart the Phoenix server, and your changes will be live.
