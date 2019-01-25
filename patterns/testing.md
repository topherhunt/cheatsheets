# Testing


## General philosophy

- Don't aim for 100% coverage. Aim for a *consistent* high level of coverage and a *predictable*, easy-to-navigate test suite.
- The test suite should be structured intentionally, not grown organically. Maintain it at a consistent level.
- Use helper methods & helper modules liberally to optimize for readability & conciseness in the tests.


## Controller tests

- Are the most consistent & thorough testing boundary
- Should cover every endpoint, every pathway, and every important outcome / side effect


## Unit tests

- Test judiciously to cover any complex logic and any code you're particularly worried about
- In Phoenix, just testing each context's public API should be enough. No need to test the contained schemas etc. directly.


## Integration / feature tests

- Should cover each form, filling in then checking the result of *each field* (there's no other way to confirm that a form is wired up properly)
- Should exercise any critical-path JS logic
- Should always start from the homepage (so navigation is nominally exercised)
- Should otherwise be as brief, minimal, standard, and boring as possible
