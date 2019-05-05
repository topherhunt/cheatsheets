# Troubleshooting Elixir & Phoenix problems


## Nonsensical errors that don't correspond to the current code

It's possible for the compiled beam files to not "realize" that they're stale and need recompiling. If you're clear that the output just doesn't correspond to the current state of the code, rm -rf build/ and deps/, then fetch and compile again.
