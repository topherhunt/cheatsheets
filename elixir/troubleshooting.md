# Troubleshooting in Elixir & Phoenix


## Nonsensical errors that don't correspond to the current code

It's possible for the compiled beam files to not "realize" that they're stale and need recompiling. If you're clear that the output just doesn't correspond to the current state of the code, rm -rf build/ and deps/, then fetch and compile again.


## Stacktrace omits certain files/functions

This happens because of tail call optimization, which drops intermediary function calls when the return value is another function call. Solution: To ensure that a function will show up in the stacktrace,

See:

  * https://stackoverflow.com/a/56019718/1729692
  * https://github.com/elixir-lang/elixir/issues/6357
