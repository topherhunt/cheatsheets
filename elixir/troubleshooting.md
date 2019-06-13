# Troubleshooting in Elixir & Phoenix


## Nonsensical errors that don't correspond to the current code

It's possible for the compiled beam files to not "realize" that they're stale and need recompiling. If you're clear that the output just doesn't correspond to the current state of the code, rm -rf build/ and deps/, then fetch and compile again.


## Stacktrace omits certain files/functions

This happens because of tail call optimization, which drops intermediary function calls when the return value is another function call. Solution: To ensure that a function will show up in the stacktrace,

See:

  * https://stackoverflow.com/a/56019718/1729692
  * https://github.com/elixir-lang/elixir/issues/6357


## (Phoenix) Uncaught TypeError: Cannot assign to read only property '0' of string

If on re-render you get a JS error about "Uncaught TypeError: Cannot assign to read only property '0' of string 'some dom fragment being rendered', it's likely that your LiveView `.leex` template markup is invalid. Check for misplaced div tags, especially around any nested if / end statements.
