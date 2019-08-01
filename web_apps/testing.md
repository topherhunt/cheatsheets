# Testing


## General philosophy

  * Don't aim for 100% coverage. Aim for a *consistent* high level of coverage and a *predictable*, easy-to-navigate test suite.
  * The test suite should be structured intentionally, not grown organically. Maintain it at a consistent level.
  * Use helper methods & helper modules liberally to keep the test examples concise, consistently structured, and easy to read.


## Controller tests

  * Are the most consistent & thorough testing boundary
  * Should cover every endpoint, every logic pathway, and every important outcome / side effect.


## Unit tests

  * (in Phoenix) Schema validations should be tested at the context layer, ie. by attempting an insert and asserting that it failed. Don't do tests that reach inside the schema, unless there's a specific bit of complex logic that I want extra coverage for.
  * There should be tests covering any complex custom logic / code you're particularly worried about


## Integration / feature tests

  * Should cover each form, filling in then checking the result of *each field* (there's no other way to confirm that a form is wired up properly)
  * Should exercise any critical-path JS logic
  * Should always start from the homepage (so navigation is nominally exercised)
  * Should otherwise be as brief, minimal, standard, and boring as possible
